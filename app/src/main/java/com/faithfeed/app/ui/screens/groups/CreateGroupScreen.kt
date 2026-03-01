package com.faithfeed.app.ui.screens.groups

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.systemBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import com.faithfeed.app.navigation.Route
import com.faithfeed.app.ui.components.ButtonStyle
import com.faithfeed.app.ui.components.FaithFeedButton
import com.faithfeed.app.ui.components.GlassCard
import com.faithfeed.app.ui.components.SimpleTopBar
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.Nunito
import com.faithfeed.app.ui.theme.Typography

@Composable
fun CreateGroupScreen(
    navController: NavController,
    viewModel: CreateGroupViewModel = hiltViewModel()
) {
    val name by viewModel.name.collectAsStateWithLifecycle()
    val description by viewModel.description.collectAsStateWithLifecycle()
    val isPrivate by viewModel.isPrivate.collectAsStateWithLifecycle()
    val isSubmitting by viewModel.isSubmitting.collectAsStateWithLifecycle()
    val error by viewModel.error.collectAsStateWithLifecycle()

    Column(
        modifier = Modifier
            .fillMaxSize()
            .background(FaithFeedColors.BackgroundPrimary)
            .systemBarsPadding()
            .imePadding()
    ) {
        SimpleTopBar(title = "Create Group", onBack = { navController.popBackStack() })

        Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState())
                .padding(16.dp)
        ) {
            GlassCard(modifier = Modifier.fillMaxWidth()) {
                Column {
                    // Group name
                    Text(
                        text = "Group Name *",
                        fontFamily = Nunito,
                        fontWeight = FontWeight.SemiBold,
                        color = FaithFeedColors.TextSecondary
                    )
                    Spacer(Modifier.height(8.dp))
                    OutlinedTextField(
                        value = name,
                        onValueChange = viewModel::onNameChange,
                        placeholder = { Text("e.g. Women's Bible Study", fontFamily = Nunito, color = FaithFeedColors.TextTertiary) },
                        singleLine = true,
                        colors = groupFieldColors(),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.fillMaxWidth()
                    )

                    Spacer(Modifier.height(16.dp))

                    // Description
                    Text(
                        text = "Description",
                        fontFamily = Nunito,
                        fontWeight = FontWeight.SemiBold,
                        color = FaithFeedColors.TextSecondary
                    )
                    Spacer(Modifier.height(8.dp))
                    OutlinedTextField(
                        value = description,
                        onValueChange = viewModel::onDescriptionChange,
                        placeholder = { Text("What is this group about?", fontFamily = Nunito, color = FaithFeedColors.TextTertiary) },
                        minLines = 3,
                        maxLines = 5,
                        colors = groupFieldColors(),
                        shape = RoundedCornerShape(12.dp),
                        modifier = Modifier.fillMaxWidth()
                    )

                    Spacer(Modifier.height(16.dp))

                    // Private toggle
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = "Private Group",
                                fontFamily = Nunito,
                                fontWeight = FontWeight.SemiBold,
                                color = FaithFeedColors.TextPrimary
                            )
                            Text(
                                text = "Only invited members can join",
                                style = Typography.bodySmall,
                                color = FaithFeedColors.TextTertiary
                            )
                        }
                        Switch(
                            checked = isPrivate,
                            onCheckedChange = viewModel::onPrivacyChange,
                            colors = SwitchDefaults.colors(
                                checkedThumbColor = FaithFeedColors.BackgroundPrimary,
                                checkedTrackColor = FaithFeedColors.GoldAccent,
                                uncheckedThumbColor = FaithFeedColors.TextTertiary,
                                uncheckedTrackColor = FaithFeedColors.GlassBackground
                            )
                        )
                    }

                    if (error != null) {
                        Spacer(Modifier.height(12.dp))
                        Text(
                            text = error!!,
                            fontFamily = Nunito,
                            color = androidx.compose.ui.graphics.Color(0xFFFF6B6B)
                        )
                    }

                    Spacer(Modifier.height(24.dp))

                    Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                        if (isSubmitting) {
                            CircularProgressIndicator(
                                color = FaithFeedColors.GoldAccent,
                                modifier = Modifier.size(40.dp)
                            )
                        } else {
                            FaithFeedButton(
                                text = "Create Group",
                                onClick = {
                                    viewModel.createGroup { groupId ->
                                        navController.navigate(Route.GroupDetail(groupId)) {
                                            popUpTo(Route.CreateGroup) { inclusive = true }
                                        }
                                    }
                                },
                                modifier = Modifier.fillMaxWidth(),
                                style = ButtonStyle.Primary
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun groupFieldColors() = OutlinedTextFieldDefaults.colors(
    focusedBorderColor = FaithFeedColors.GoldAccent,
    unfocusedBorderColor = FaithFeedColors.GlassBorder,
    focusedTextColor = FaithFeedColors.TextPrimary,
    unfocusedTextColor = FaithFeedColors.TextPrimary,
    cursorColor = FaithFeedColors.GoldAccent,
    focusedContainerColor = FaithFeedColors.GlassBackground,
    unfocusedContainerColor = FaithFeedColors.GlassBackground
)
