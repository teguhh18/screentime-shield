package com.inibudi.screentimeshield.utils

/**
 * Sealed class for structured MethodChannel responses.
 *
 * Used by all handler classes to return type-safe results
 * to [MainActivity], which then converts them into
 * MethodChannel success/error calls.
 *
 * Per SKILL.md: Kotlin sealed classes + Dart enums for
 * MethodChannel response handling.
 */
sealed class ChannelResult {

    /**
     * Successful operation with optional data payload.
     * @param data The result data (Map, List, Boolean, String, etc.)
     */
    data class Success(val data: Any? = null) : ChannelResult()

    /**
     * Failed operation with error code and human-readable message.
     * @param code Machine-readable error code (e.g., "PERMISSION_DENIED")
     * @param message User-readable error description
     * @param details Optional additional error details
     */
    data class Error(
        val code: String,
        val message: String,
        val details: Any? = null
    ) : ChannelResult()
}
