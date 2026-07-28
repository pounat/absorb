package com.barnabas.absorb

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class CoverRefreshTokensTest {
    @Test
    fun parsesNestedUserTokenPair() {
        val tokens = parseCoverRefreshTokens(
            """{"success":true,"user":{"accessToken":"access","refreshToken":"refresh"}}""",
        )

        assertEquals("access", tokens?.accessToken)
        assertEquals("refresh", tokens?.refreshToken)
    }

    @Test
    fun rejectsHalfATokenPair() {
        assertNull(parseCoverRefreshTokens("""{"accessToken":"access"}"""))
    }
}
