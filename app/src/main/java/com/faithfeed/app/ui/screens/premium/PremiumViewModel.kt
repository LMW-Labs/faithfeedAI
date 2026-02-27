package com.faithfeed.app.ui.screens.premium

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class PremiumPlan(
    val id: String = "",
    val name: String = "",
    val price: String = "",
    val period: String = "",
    val features: List<String> = emptyList()
)

enum class PurchaseState { IDLE, LOADING, SUCCESS, ERROR }

@HiltViewModel
class PremiumViewModel @Inject constructor() : ViewModel() {
    private val _plans = MutableStateFlow<List<PremiumPlan>>(emptyList())
    val plans: StateFlow<List<PremiumPlan>> = _plans.asStateFlow()

    private val _purchaseState = MutableStateFlow(PurchaseState.IDLE)
    val purchaseState: StateFlow<PurchaseState> = _purchaseState.asStateFlow()

    private val _currentSubscription = MutableStateFlow<PremiumPlan?>(null)
    val currentSubscription: StateFlow<PremiumPlan?> = _currentSubscription.asStateFlow()

    private val _error = MutableStateFlow<String?>(null)
    val error: StateFlow<String?> = _error.asStateFlow()

    init {
        loadPlans()
    }

    private fun loadPlans() {
        viewModelScope.launch {
            // TODO: Load SKUs from Google Play Billing client
            _plans.value = listOf(
                PremiumPlan("monthly", "FaithFeed Premium", "$4.99", "month", listOf("Unlimited AI study sessions", "Ad-free experience", "Priority prayer wall", "Exclusive devotionals")),
                PremiumPlan("yearly", "FaithFeed Premium", "$39.99", "year", listOf("All monthly features", "Save 33%", "Early access to new features", "Premium badge"))
            )
        }
    }

    fun purchase(plan: PremiumPlan) {
        viewModelScope.launch {
            _purchaseState.value = PurchaseState.LOADING
            // TODO: initiate Google Play Billing purchase flow
            _purchaseState.value = PurchaseState.IDLE
        }
    }
}
