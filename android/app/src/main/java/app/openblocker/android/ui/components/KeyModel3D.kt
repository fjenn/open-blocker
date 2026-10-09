package app.openblocker.android.ui.components

import android.content.Context
import android.graphics.SurfaceTexture
import android.opengl.Matrix
import android.view.Choreographer
import android.view.TextureView
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.viewinterop.AndroidView
import com.google.android.filament.Box
import com.google.android.filament.Camera
import com.google.android.filament.Engine
import com.google.android.filament.Entity
import com.google.android.filament.EntityManager
import com.google.android.filament.IndirectLight
import com.google.android.filament.LightManager
import com.google.android.filament.Renderer
import com.google.android.filament.Scene
import com.google.android.filament.Skybox
import com.google.android.filament.SwapChain
import com.google.android.filament.View
import com.google.android.filament.Viewport
import com.google.android.filament.gltfio.AssetLoader
import com.google.android.filament.gltfio.FilamentAsset
import com.google.android.filament.gltfio.ResourceLoader
import com.google.android.filament.gltfio.UbershaderProvider
import com.google.android.filament.utils.Utils
import java.nio.ByteBuffer
import java.nio.ByteOrder
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.tan

/**
 * Filament renderer for the iPhone KeyModel.glb. Lighting matches iOS KeyView3D:
 * matte body 0x9A9690, environment intensity 0.7, key light from the top left.
 * Hold fill and lock burst stay in Compose (screen space), same as iOS.
 */
@Composable
fun KeyModel3D(
    yaw: Float,
    modifier: Modifier = Modifier,
    onFailed: () -> Unit = {}
) {
    var failed by remember { mutableStateOf(false) }
    if (failed) return
    AndroidView(
        modifier = modifier.fillMaxSize(),
        factory = { context ->
            KeyFilamentView(context) {
                failed = true
                onFailed()
            }
        },
        update = { view -> view.yawRadians = yaw }
    )
}

internal object KeyNatives {
    @Volatile
    private var state: Boolean? = null

    fun available(): Boolean {
        state?.let { return it }
        return try {
            Utils.init()
            state = true
            true
        } catch (_: Throwable) {
            state = false
            false
        }
    }
}

internal class KeyFilamentView(
    context: Context,
    private val onFailed: () -> Unit
) : TextureView(context), TextureView.SurfaceTextureListener, Choreographer.FrameCallback {

    @Volatile
    var yawRadians: Float = 0.18f

    private val choreographer = Choreographer.getInstance()
    private var engine: Engine? = null
    private var renderer: Renderer? = null
    private var scene: Scene? = null
    private var view: View? = null
    private var camera: Camera? = null
    private var swapChain: SwapChain? = null
    private var assetLoader: AssetLoader? = null
    private var resourceLoader: ResourceLoader? = null
    private var asset: FilamentAsset? = null
    private var skybox: Skybox? = null
    private var indirectLight: IndirectLight? = null
    @Entity private var cameraEntity = 0
    @Entity private var keyLight = 0
    @Entity private var fillLight = 0
    private var attached = false
    private var ready = false
    private val modelMatrix = FloatArray(16)
    private var centerX = 0f
    private var centerY = 0f
    private var centerZ = 0f

    init {
        isOpaque = false
        surfaceTextureListener = this
        if (!KeyNatives.available()) {
            onFailed()
        }
    }

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        attached = true
        choreographer.postFrameCallback(this)
    }

    override fun onDetachedFromWindow() {
        attached = false
        choreographer.removeFrameCallback(this)
        destroy()
        super.onDetachedFromWindow()
    }

    override fun onSurfaceTextureAvailable(surface: SurfaceTexture, width: Int, height: Int) {
        try {
            if (engine == null) createScene()
            val eng = engine ?: return
            swapChain?.let { eng.destroySwapChain(it) }
            swapChain = eng.createSwapChain(android.view.Surface(surface))
            resize(width, height)
            ready = true
        } catch (_: Throwable) {
            ready = false
            onFailed()
        }
    }

    override fun onSurfaceTextureSizeChanged(surface: SurfaceTexture, width: Int, height: Int) {
        resize(width, height)
    }

    override fun onSurfaceTextureDestroyed(surface: SurfaceTexture): Boolean {
        ready = false
        val eng = engine
        swapChain?.let { if (eng != null) eng.destroySwapChain(it) }
        swapChain = null
        return true
    }

    override fun onSurfaceTextureUpdated(surface: SurfaceTexture) {}

    override fun doFrame(frameTimeNanos: Long) {
        if (attached) choreographer.postFrameCallback(this)
        if (!ready) return
        if (engine == null) return
        val rend = renderer ?: return
        if (scene == null) return
        val vw = view ?: return
        val chain = swapChain ?: return
        applyYaw()
        if (rend.beginFrame(chain, frameTimeNanos)) {
            rend.render(vw)
            rend.endFrame()
        }
    }

    private fun createScene() {
        val eng = Engine.create()
        engine = eng
        renderer = eng.createRenderer()
        val options = renderer!!.clearOptions
        options.clear = true
        options.clearColor[0] = 0f
        options.clearColor[1] = 0f
        options.clearColor[2] = 0f
        options.clearColor[3] = 0f
        renderer!!.clearOptions = options

        scene = eng.createScene()
        view = eng.createView()
        cameraEntity = EntityManager.get().create()
        camera = eng.createCamera(cameraEntity)
        view!!.scene = scene
        view!!.camera = camera
        view!!.blendMode = View.BlendMode.TRANSLUCENT
        view!!.isPostProcessingEnabled = false

        skybox = Skybox.Builder().color(0f, 0f, 0f, 0f).build(eng)
        scene!!.skybox = skybox
        try {
            indirectLight = IndirectLight.Builder()
                .intensity(30_000f * 0.7f)
                .build(eng)
            scene!!.indirectLight = indirectLight
        } catch (_: Throwable) {
            indirectLight = null
        }

        keyLight = EntityManager.get().create()
        LightManager.Builder(LightManager.Type.DIRECTIONAL)
            .color(1f, 1f, 1f)
            .intensity(70_000f)
            .direction(0.45f, -0.85f, -0.40f)
            .castShadows(false)
            .build(eng, keyLight)
        scene!!.addEntity(keyLight)

        fillLight = EntityManager.get().create()
        LightManager.Builder(LightManager.Type.DIRECTIONAL)
            .color(1f, 1f, 1f)
            .intensity(16_000f)
            .direction(-0.55f, -0.35f, -0.20f)
            .castShadows(false)
            .build(eng, fillLight)
        scene!!.addEntity(fillLight)

        loadModel(eng)
        frameCamera()
    }

    private fun loadModel(eng: Engine) {
        val provider = UbershaderProvider(eng)
        val loader = AssetLoader(eng, provider, EntityManager.get())
        val resources = ResourceLoader(eng)
        assetLoader = loader
        resourceLoader = resources
        val buffer = readAsset("models/KeyModel.glb")
        val loaded = loader.createAsset(buffer) ?: throw IllegalStateException("KeyModel.glb")
        resources.loadResources(loaded)
        loaded.releaseSourceData()
        asset = loaded
        scene!!.addEntities(loaded.entities)
        paintBody(loaded)
        val box: Box = loaded.boundingBox
        val c = box.center
        centerX = c[0]
        centerY = c[1]
        centerZ = c[2]
    }

    private fun paintBody(loaded: FilamentAsset) {
        val r = 0x9A / 255f
        val g = 0x96 / 255f
        val b = 0x90 / 255f
        for (entity in loaded.entities) {
            val renderable = engine!!.renderableManager.getInstance(entity)
            if (renderable == 0) continue
            val count = engine!!.renderableManager.getPrimitiveCount(renderable)
            for (i in 0 until count) {
                val material = engine!!.renderableManager.getMaterialInstanceAt(renderable, i)
                try {
                    material.setParameter("baseColorFactor", r, g, b, 1f)
                } catch (_: Throwable) {
                }
                try {
                    material.setParameter("roughnessFactor", 0.82f)
                } catch (_: Throwable) {
                }
                try {
                    material.setParameter("metallicFactor", 0f)
                } catch (_: Throwable) {
                }
            }
        }
    }

    private fun frameCamera() {
        val cam = camera ?: return
        val loaded = asset ?: return
        val half = loaded.boundingBox.halfExtent
        val radius = maxOf(half[0], half[2], 0.08f)
        val fov = 26.0
        val elevation = Math.toRadians(50.0)
        val distance = (radius / tan(Math.toRadians(fov * 0.5 * 0.78))).toFloat()
        val eyeX = centerX
        val eyeY = centerY + sin(elevation).toFloat() * distance
        val eyeZ = centerZ + cos(elevation).toFloat() * distance
        cam.setExposure(16f, 1f / 125f, 100f)
        cam.setProjection(fov, 1.0, 0.05, 50.0, Camera.Fov.VERTICAL)
        cam.lookAt(eyeX.toDouble(), eyeY.toDouble(), eyeZ.toDouble(), centerX.toDouble(), centerY.toDouble(), centerZ.toDouble(), 0.0, 1.0, 0.0)
    }

    private fun resize(width: Int, height: Int) {
        if (width <= 0 || height <= 0) return
        view?.viewport = Viewport(0, 0, width, height)
        val aspect = width.toDouble() / height.toDouble()
        camera?.setProjection(26.0, aspect, 0.05, 50.0, Camera.Fov.VERTICAL)
    }

    private fun applyYaw() {
        val loaded = asset ?: return
        val tm = engine?.transformManager ?: return
        val inst = tm.getInstance(loaded.root)
        if (inst == 0) return
        Matrix.setIdentityM(modelMatrix, 0)
        Matrix.translateM(modelMatrix, 0, centerX, centerY, centerZ)
        Matrix.rotateM(modelMatrix, 0, Math.toDegrees(yawRadians.toDouble()).toFloat(), 0f, 1f, 0f)
        Matrix.translateM(modelMatrix, 0, -centerX, -centerY, -centerZ)
        tm.setTransform(inst, modelMatrix)
    }

    private fun readAsset(path: String): ByteBuffer {
        context.assets.open(path).use { input ->
            val bytes = input.readBytes()
            val buffer = ByteBuffer.allocateDirect(bytes.size).order(ByteOrder.nativeOrder())
            buffer.put(bytes)
            buffer.flip()
            return buffer
        }
    }

    private fun destroy() {
        ready = false
        val eng = engine ?: return
        try {
            swapChain?.let { eng.destroySwapChain(it) }
            swapChain = null
            asset?.let { loaded ->
                scene?.removeEntities(loaded.entities)
                assetLoader?.destroyAsset(loaded)
            }
            asset = null
            resourceLoader?.destroy()
            resourceLoader = null
            assetLoader?.destroy()
            assetLoader = null
            if (keyLight != 0) {
                scene?.removeEntity(keyLight)
                eng.destroyEntity(keyLight)
                EntityManager.get().destroy(keyLight)
                keyLight = 0
            }
            if (fillLight != 0) {
                scene?.removeEntity(fillLight)
                eng.destroyEntity(fillLight)
                EntityManager.get().destroy(fillLight)
                fillLight = 0
            }
            indirectLight?.let { eng.destroyIndirectLight(it) }
            indirectLight = null
            skybox?.let { eng.destroySkybox(it) }
            skybox = null
            view?.let { eng.destroyView(it) }
            view = null
            scene?.let { eng.destroyScene(it) }
            scene = null
            camera?.let { eng.destroyCameraComponent(cameraEntity) }
            camera = null
            if (cameraEntity != 0) {
                EntityManager.get().destroy(cameraEntity)
                cameraEntity = 0
            }
            renderer?.let { eng.destroyRenderer(it) }
            renderer = null
            eng.destroy()
        } catch (_: Throwable) {
        }
        engine = null
    }
}
