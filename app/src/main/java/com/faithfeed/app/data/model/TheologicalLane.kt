package com.faithfeed.app.data.model

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/**
 * Represents a theological lane detected by the Supabase RPC `detect_theological_lanes`.
 *
 * [laneKey]       - stable machine key (e.g. "predestination", "eschatology")
 * [label]         - human-readable display name shown in the banner
 * [disclosureText]- short explanation of why this topic is flagged
 * [severity]      - "low" | "moderate" | "high" — drives accent color
 * [score]         - confidence / relevance score (0.0–1.0) returned by the RPC
 */
@Serializable
data class TheologicalLane(
    @SerialName("lane_key")       val laneKey: String = "",
    val label: String = "",
    @SerialName("disclosure_text") val disclosureText: String = "",
    val severity: String = "low",
    val score: Double = 0.0
)
