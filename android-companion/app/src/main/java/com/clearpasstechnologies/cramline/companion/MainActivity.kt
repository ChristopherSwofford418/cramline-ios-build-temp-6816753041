package com.clearpasstechnologies.cramline.companion

import android.annotation.SuppressLint
import android.content.Intent
import android.os.Bundle
import android.provider.Settings
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Button
import androidx.compose.material3.Checkbox
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Slider
import androidx.compose.material3.Text
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp

object CompanionClaims {
    const val TITLE = "Manual Focus Companion"
    const val BOUNDARY = "This Android version plans your study sprint and explains Android’s own Digital Wellbeing controls. It does not block, shield, monitor, or interrupt other apps."
    const val PRIVACY = "No app inventory, Usage Access, Accessibility Service, notifications, browsing data, or activity content is requested."
}

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            MaterialTheme {
                CompanionScreen()
            }
        }
    }
}

@androidx.compose.runtime.Composable
@SuppressLint("UseKtx")
private fun CompanionScreen() {
    val context = LocalContext.current
    val preferences = remember { context.getSharedPreferences("cramline-local-plan", android.content.Context.MODE_PRIVATE) }
    var adultConfirmed by remember { mutableStateOf(false) }
    var sprintDays by remember { mutableFloatStateOf(preferences.getFloat("sprint-days", 30f)) }
    var planSaved by remember { mutableStateOf(preferences.contains("sprint-days")) }

    Scaffold { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(20.dp)
                .verticalScroll(rememberScrollState()),
            verticalArrangement = Arrangement.spacedBy(18.dp),
        ) {
            Text(CompanionClaims.TITLE, style = MaterialTheme.typography.headlineLarge)
            Text(CompanionClaims.BOUNDARY, style = MaterialTheme.typography.bodyLarge)
            Text(CompanionClaims.PRIVACY, style = MaterialTheme.typography.bodyMedium)

            Row(verticalAlignment = Alignment.CenterVertically) {
                Checkbox(
                    checked = adultConfirmed,
                    onCheckedChange = { adultConfirmed = it },
                    modifier = Modifier.semantics { contentDescription = "I confirm I am 18 or older" },
                )
                Text("I confirm I am 18 or older")
            }

            Text("Study sprint: ${sprintDays.toInt()} days", style = MaterialTheme.typography.titleMedium)
            Slider(
                value = sprintDays,
                onValueChange = { sprintDays = it },
                valueRange = 14f..90f,
                steps = 75,
                enabled = adultConfirmed,
                modifier = Modifier.semantics { contentDescription = "Study sprint length in days" },
            )

            Button(
                onClick = {
                    preferences.edit().putFloat("sprint-days", sprintDays).apply()
                    planSaved = true
                },
                enabled = adultConfirmed,
                modifier = Modifier.fillMaxWidth(),
            ) {
                Text("Save local sprint plan")
            }
            if (planSaved) {
                Text("Saved on this device. Next, set optional app timers in Android Settings.")
            }

            Text("Set Android’s own controls", style = MaterialTheme.typography.titleLarge)
            Text("1. Open Settings.\n2. Find Digital Wellbeing & parental controls.\n3. Choose Dashboard or App timers.\n4. Set limits yourself and confirm which apps are affected.\n\nNames and availability vary by device maker. This companion cannot verify or change those settings.")
            OutlinedButton(
                onClick = { context.startActivity(Intent(Settings.ACTION_SETTINGS)) },
                modifier = Modifier.fillMaxWidth(),
            ) {
                Text("Open Android Settings")
            }

            Text("Emergency access", style = MaterialTheme.typography.titleLarge)
            Text("Any limits are controlled by Android’s settings. Use those settings to change or remove them at any time. This companion never requires payment, a passcode, a delay, or another person’s permission.")
        }
    }
}
