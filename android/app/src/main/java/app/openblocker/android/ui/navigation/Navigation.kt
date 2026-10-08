package app.openblocker.android.ui.navigation

import androidx.compose.runtime.Composable
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.rememberNavController
import app.openblocker.android.ui.screens.HomeScreen
import app.openblocker.android.ui.screens.AppPickerScreen
import app.openblocker.android.ui.screens.TagPairingScreen
import app.openblocker.android.ui.screens.AnyCardPairingScreen
import app.openblocker.android.ui.screens.DebugScreen
import app.openblocker.android.ui.screens.QrKeyScreen

sealed class Screen(val route: String) {
    object Home : Screen("home")
    object AppPicker : Screen("app_picker")
    object TagPairing : Screen("tag_pairing")
    object AnyCardPairing : Screen("any_card_pairing")
    object QrKey : Screen("qr_key")
    object Debug : Screen("debug")
}

@Composable
fun AppNavigation() {
    val navController = rememberNavController()
    
    NavHost(navController = navController, startDestination = Screen.Home.route) {
        composable(Screen.Home.route) {
            HomeScreen(
                onNavigateToAppPicker = { navController.navigate(Screen.AppPicker.route) },
                onNavigateToTagPairing = { navController.navigate(Screen.TagPairing.route) },
                onNavigateToQrKey = { navController.navigate(Screen.QrKey.route) },
                onNavigateToDebug = { navController.navigate(Screen.Debug.route) }
            )
        }
        
        composable(Screen.AppPicker.route) {
            AppPickerScreen(
                onBack = { navController.popBackStack() }
            )
        }
        
        composable(Screen.TagPairing.route) {
            TagPairingScreen(
                onBack = { navController.popBackStack() },
                onNavigateToAnyCard = { navController.navigate(Screen.AnyCardPairing.route) }
            )
        }
        
        composable(Screen.AnyCardPairing.route) {
            AnyCardPairingScreen(
                onBack = { navController.popBackStack() }
            )
        }

        composable(Screen.QrKey.route) {
            QrKeyScreen(
                onBack = { navController.popBackStack() }
            )
        }
        
        composable(Screen.Debug.route) {
            DebugScreen(
                onBack = { navController.popBackStack() }
            )
        }
    }
}
