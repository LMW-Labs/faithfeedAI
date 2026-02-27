package com.faithfeed.app.data.model

import androidx.compose.runtime.Immutable
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Immutable
@Serializable
data class MarketplaceItem(
    val id: String = "",
    @SerialName("seller_id") val sellerId: String = "",
    val title: String = "",
    val description: String = "",
    val price: Double = 0.0,
    @SerialName("item_type") val itemType: String = "physical",
    val category: String = "",
    @SerialName("media_urls") val mediaUrls: List<String> = emptyList(),
    @SerialName("is_available") val isAvailable: Boolean = true,
    val condition: String = "new",
    val location: String = "",
    @SerialName("created_at") val createdAt: String = "",
    val seller: User? = null
) {
    val isDonation get() = itemType == "donation"
    val priceDisplay get() = if (isDonation) "Free / Donate" else "$${"%.2f".format(price)}"
}
