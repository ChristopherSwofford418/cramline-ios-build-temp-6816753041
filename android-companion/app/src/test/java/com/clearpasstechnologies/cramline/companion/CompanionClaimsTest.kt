package com.clearpasstechnologies.cramline.companion

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class CompanionClaimsTest {
    @Test
    fun boundaryTruthfullyDeniesEnforcement() {
        val text = CompanionClaims.BOUNDARY.lowercase()
        assertTrue(text.contains("does not block"))
        assertTrue(text.contains("android"))
    }

    @Test
    fun claimsAvoidForbiddenEquivalence() {
        val combined = listOf(CompanionClaims.TITLE, CompanionClaims.BOUNDARY, CompanionClaims.PRIVACY).joinToString(" ").lowercase()
        assertFalse(combined.contains("hard blocker"))
        assertFalse(combined.contains("system shield"))
        assertFalse(combined.contains("unbreakable"))
        assertFalse(combined.contains("locks your phone"))
    }
}
