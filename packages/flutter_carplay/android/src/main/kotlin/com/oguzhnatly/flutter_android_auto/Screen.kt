package com.oguzhnatly.flutter_android_auto


import android.Manifest
import android.content.Intent
import android.net.Uri
import android.service.credentials.Action
import android.text.Spannable
import android.text.SpannableString
import androidx.annotation.OptIn
import androidx.car.app.CarAppService
import androidx.car.app.CarContext
import androidx.car.app.Screen
import androidx.car.app.Session
import androidx.car.app.annotations.ExperimentalCarApi
import androidx.car.app.model.CarLocation
import androidx.car.app.model.ItemList
import androidx.car.app.model.Metadata
import androidx.car.app.model.PlaceListMapTemplate
import androidx.car.app.model.PlaceMarker
import androidx.car.app.model.Row
import androidx.car.app.model.Template
import androidx.car.app.model.Header
import androidx.car.app.model.ListTemplate
import androidx.car.app.versioning.CarAppApiLevels

class MainScreen(carContext: CarContext) : Screen(carContext) {
    init {}

    @Suppress("DEPRECATION")
    override fun onGetTemplate(): Template {
        val appName =
            carContext.applicationInfo.loadLabel(carContext.packageManager)
                .toString() ?: ""

        FlutterAndroidAutoPlugin.currentTemplate?.let { return it }

        val templateBuilder = ListTemplate.Builder().setLoading(true)
        if (carContext.carAppApiLevel >= CarAppApiLevels.LEVEL_7) {
            templateBuilder.setHeader(Header.Builder().setTitle(appName).build())
        } else {
            templateBuilder.setTitle(appName)
        }
        return templateBuilder.build()
    }
}
