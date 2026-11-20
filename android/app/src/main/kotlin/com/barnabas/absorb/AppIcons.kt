package com.barnabas.absorb

import android.content.ComponentName
import android.content.Context
import android.content.pm.PackageManager
import android.util.Log

/**
 * The app icon colors. Each is its own home screen entry (an Icon* alias of
 * MainActivity in the manifest); the picked one is turned on and the rest
 * off. Keep the ids in step with lib/utils/app_icon_palette.dart.
 */
object AppIcons {
    private val ids = listOf(
        "classic", "light", "teal", "blue", "sky", "purple", "pink", "red", "orange", "yellow", "green",
    )

    // The aliases' class names come from the namespace, which stays the same
    // in the dev build even though its package name doesn't.
    private fun alias(context: Context, id: String) = ComponentName(
        context.packageName,
        "com.barnabas.absorb.Icon" + id.replaceFirstChar { it.uppercase() },
    )

    private fun isOn(context: Context, id: String): Boolean =
        when (context.packageManager.getComponentEnabledSetting(alias(context, id))) {
            PackageManager.COMPONENT_ENABLED_STATE_ENABLED -> true
            PackageManager.COMPONENT_ENABLED_STATE_DEFAULT -> id == "classic"
            else -> false
        }

    fun current(context: Context): String = ids.firstOrNull { isOn(context, it) } ?: "classic"

    /**
     * Turns the app's shortcuts with these ids back on. Android disables a
     * pinned shortcut once the launcher entry it was made under goes away
     * (an older build, or an icon switch), and then refuses to update it,
     * which made the whole set of long-press shortcuts fail to publish.
     */
    fun enableShortcuts(context: Context, shortcutIds: List<String>) {
        if (android.os.Build.VERSION.SDK_INT < android.os.Build.VERSION_CODES.N_MR1) return
        try {
            context.getSystemService(android.content.pm.ShortcutManager::class.java)
                ?.enableShortcuts(shortcutIds)
        } catch (e: Exception) {
            Log.w("AppIcons", "turning shortcuts back on failed", e)
        }
    }

    /** The new one goes on before the others come off, so there is always a way into the app. */
    fun set(context: Context, id: String): Boolean {
        if (id !in ids) return false
        val pm = context.packageManager
        return try {
            pm.setComponentEnabledSetting(
                alias(context, id),
                PackageManager.COMPONENT_ENABLED_STATE_ENABLED,
                PackageManager.DONT_KILL_APP,
            )
            for (other in ids) {
                if (other == id) continue
                pm.setComponentEnabledSetting(
                    alias(context, other),
                    PackageManager.COMPONENT_ENABLED_STATE_DISABLED,
                    PackageManager.DONT_KILL_APP,
                )
            }
            true
        } catch (e: Exception) {
            Log.w("AppIcons", "changing the app icon failed", e)
            false
        }
    }
}
