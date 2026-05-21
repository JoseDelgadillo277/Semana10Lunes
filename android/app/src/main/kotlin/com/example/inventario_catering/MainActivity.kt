package com.example.inventario_catering

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.location.Location
import android.location.LocationListener
import android.location.LocationManager
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import androidx.core.app.ActivityCompat
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channelName = "inventario_catering/delivery"
    private val locationRequestCode = 44
    private var pendingResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
            if (call.method == "openDeliveryMap") {
                pendingResult = result
                abrirDeliveryConPermiso()
            } else {
                result.notImplemented()
            }
        }
    }

    private fun abrirDeliveryConPermiso() {
        if (tienePermisoUbicacion()) {
            obtenerUbicacionActualYAbrirMaps()
            return
        }

        ActivityCompat.requestPermissions(
            this,
            arrayOf(
                Manifest.permission.ACCESS_FINE_LOCATION,
                Manifest.permission.ACCESS_COARSE_LOCATION
            ),
            locationRequestCode
        )
    }

    private fun tienePermisoUbicacion(): Boolean {
        return ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.ACCESS_FINE_LOCATION
        ) == PackageManager.PERMISSION_GRANTED ||
            ContextCompat.checkSelfPermission(
                this,
                Manifest.permission.ACCESS_COARSE_LOCATION
            ) == PackageManager.PERMISSION_GRANTED
    }

    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)

        if (requestCode != locationRequestCode) {
            return
        }

        if (grantResults.any { it == PackageManager.PERMISSION_GRANTED }) {
            obtenerUbicacionActualYAbrirMaps()
        } else {
            pendingResult?.error("PERMISSION_DENIED", "Permiso de ubicacion denegado", null)
            pendingResult = null
        }
    }

    private fun obtenerUbicacionActualYAbrirMaps() {
        if (!tienePermisoUbicacion()) {
            pendingResult?.error("PERMISSION_DENIED", "Permiso de ubicacion denegado", null)
            pendingResult = null
            return
        }

        val locationManager = getSystemService(Context.LOCATION_SERVICE) as LocationManager
        val providers = listOf(
            LocationManager.GPS_PROVIDER,
            LocationManager.NETWORK_PROVIDER,
            LocationManager.PASSIVE_PROVIDER
        ).filter { locationManager.isProviderEnabled(it) }

        val ultimaUbicacion = obtenerUltimaUbicacionReciente(locationManager)
        if (ultimaUbicacion != null) {
            abrirGoogleMaps(ultimaUbicacion)
            return
        }

        if (providers.isEmpty()) {
            abrirGoogleMaps(null)
            return
        }

        val handler = Handler(Looper.getMainLooper())
        var completado = false

        val listener = object : LocationListener {
            override fun onLocationChanged(location: Location) {
                if (completado) return
                completado = true
                handler.removeCallbacksAndMessages(null)
                locationManager.removeUpdates(this)
                abrirGoogleMaps(location)
            }

            override fun onProviderDisabled(provider: String) {}
            override fun onProviderEnabled(provider: String) {}
            @Deprecated("Deprecated in Android")
            override fun onStatusChanged(provider: String?, status: Int, extras: Bundle?) {}
        }

        try {
            providers.forEach { provider ->
                locationManager.requestLocationUpdates(provider, 0L, 0f, listener, Looper.getMainLooper())
            }
            handler.postDelayed({
                if (!completado) {
                    completado = true
                    locationManager.removeUpdates(listener)
                    abrirGoogleMaps(obtenerUltimaUbicacionReciente(locationManager))
                }
            }, 5000)
        } catch (_: SecurityException) {
            pendingResult?.error("PERMISSION_DENIED", "Permiso de ubicacion denegado", null)
            pendingResult = null
        }
    }

    private fun obtenerUltimaUbicacionReciente(locationManager: LocationManager): Location? {
        val diezMinutos = 10 * 60 * 1000L
        val ahora = System.currentTimeMillis()

        return listOf(
            LocationManager.GPS_PROVIDER,
            LocationManager.NETWORK_PROVIDER,
            LocationManager.PASSIVE_PROVIDER
        ).mapNotNull { provider ->
            try {
                if (locationManager.isProviderEnabled(provider)) {
                    locationManager.getLastKnownLocation(provider)
                } else {
                    null
                }
            } catch (_: SecurityException) {
                null
            }
        }.filter { ahora - it.time <= diezMinutos }
            .maxByOrNull { it.time }
    }

    private fun abrirGoogleMaps(location: Location?) {
        val origen = if (location != null) {
            "${location.latitude},${location.longitude}"
        } else {
            "My Location"
        }

        val uri = Uri.parse(
            "https://www.google.com/maps/dir/?api=1" +
                "&origin=${Uri.encode(origen)}" +
                "&destination=${Uri.encode("Plaza Vea Huancayo")}" +
                "&travelmode=driving"
        )

        val intent = Intent(Intent.ACTION_VIEW, uri).apply {
            setPackage("com.google.android.apps.maps")
        }

        try {
            startActivity(intent)
        } catch (_: Exception) {
            startActivity(Intent(Intent.ACTION_VIEW, uri))
        }

        pendingResult?.success(true)
        pendingResult = null
    }
}
