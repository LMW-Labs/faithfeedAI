package com.faithfeed.app.ui.screens.explore

import android.Manifest
import android.content.Intent
import android.content.pm.PackageManager
import android.os.Bundle
import android.speech.RecognitionListener
import android.speech.RecognizerIntent
import android.speech.SpeechRecognizer
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.core.EaseInOut
import androidx.compose.animation.core.RepeatMode
import androidx.compose.animation.core.animateFloat
import androidx.compose.animation.core.infiniteRepeatable
import androidx.compose.animation.core.rememberInfiniteTransition
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.lazy.rememberLazyListState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.outlined.*
import androidx.compose.material.icons.automirrored.outlined.Send
import androidx.compose.material.icons.automirrored.outlined.VolumeOff
import androidx.compose.material.icons.automirrored.outlined.VolumeUp
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material.icons.outlined.AddCircleOutline
import androidx.compose.material.icons.outlined.CheckCircle
import androidx.compose.material.icons.outlined.GraphicEq
import androidx.compose.material.icons.outlined.Psychology
import androidx.compose.material.icons.outlined.RecordVoiceOver
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.IconButton
import androidx.compose.material3.IconButtonDefaults
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.OutlinedTextFieldDefaults
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.scale
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.text.font.FontStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.navigation.NavController
import com.faithfeed.app.R
import com.faithfeed.app.data.model.AIMessage
import com.faithfeed.app.data.service.TTS_VOICES
import com.faithfeed.app.navigation.Route
import com.faithfeed.app.ui.components.SimpleTopBar
import com.faithfeed.app.ui.components.TheologicalDisclosureBanner
import com.faithfeed.app.ui.theme.FaithFeedColors
import com.faithfeed.app.ui.theme.Nunito
import com.faithfeed.app.ui.theme.Typography
import kotlinx.coroutines.launch
import androidx.compose.foundation.Image
import androidx.compose.foundation.combinedClickable
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.ui.platform.LocalClipboardManager
import androidx.compose.ui.res.painterResource
import androidx.compose.ui.text.AnnotatedString

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AIStudyPartnerScreen(
    navController: NavController,
    viewModel: AIStudyPartnerViewModel = hiltViewModel()
) {
    val messages by viewModel.messages.collectAsStateWithLifecycle()
    val isLoading by viewModel.isLoading.collectAsStateWithLifecycle()
    val isListening by viewModel.isListening.collectAsStateWithLifecycle()
    val isSpeaking by viewModel.isSpeaking.collectAsStateWithLifecycle()
    val isMuted by viewModel.isMuted.collectAsStateWithLifecycle()
    val selectedVoice by viewModel.selectedVoice.collectAsStateWithLifecycle()
    val showVoiceSettings by viewModel.showVoiceSettings.collectAsStateWithLifecycle()
    val detectedLanes by viewModel.detectedLanes.collectAsStateWithLifecycle()

    var inputText by remember { mutableStateOf("") }
    val focusManager = LocalFocusManager.current
    val listState = rememberLazyListState()
    val context = LocalContext.current
    val scope = rememberCoroutineScope()

    // ── Permission launcher ────────────────────────────────────────────────────
    val permissionLauncher = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        if (granted) viewModel.onMicTap()
    }

    // ── SpeechRecognizer lifecycle ─────────────────────────────────────────────
    var speechRecognizer by remember { mutableStateOf<SpeechRecognizer?>(null) }

    DisposableEffect(Unit) {
        speechRecognizer = if (SpeechRecognizer.isRecognitionAvailable(context)) {
            SpeechRecognizer.createSpeechRecognizer(context).also { sr ->
                sr.setRecognitionListener(object : RecognitionListener {
                    override fun onReadyForSpeech(params: Bundle?) {}
                    override fun onBeginningOfSpeech() {}
                    override fun onRmsChanged(rmsdB: Float) {}
                    override fun onBufferReceived(buffer: ByteArray?) {}
                    override fun onEndOfSpeech() {}
                    override fun onPartialResults(partialResults: Bundle?) {
                        val text = partialResults
                            ?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                            ?.firstOrNull() ?: return
                        inputText = text
                    }
                    override fun onResults(results: Bundle?) {
                        val text = results
                            ?.getStringArrayList(SpeechRecognizer.RESULTS_RECOGNITION)
                            ?.firstOrNull() ?: return
                        inputText = ""
                        viewModel.onVoiceResult(text)
                    }
                    override fun onError(error: Int) {
                        viewModel.stopListening()
                    }
                    override fun onEvent(eventType: Int, params: Bundle?) {}
                })
            }
        } else null
        onDispose {
            speechRecognizer?.destroy()
            speechRecognizer = null
        }
    }

    // Start/stop STT in sync with ViewModel's isListening flag
    LaunchedEffect(isListening) {
        if (isListening) {
            val intent = Intent(RecognizerIntent.ACTION_RECOGNIZE_SPEECH).apply {
                putExtra(RecognizerIntent.EXTRA_LANGUAGE_MODEL, RecognizerIntent.LANGUAGE_MODEL_FREE_FORM)
                putExtra(RecognizerIntent.EXTRA_PARTIAL_RESULTS, true)
                putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_POSSIBLY_COMPLETE_SILENCE_LENGTH_MILLIS, 3000L)
                putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS, 3500L)
                putExtra(RecognizerIntent.EXTRA_SPEECH_INPUT_MINIMUM_LENGTH_MILLIS, 500L)
            }
            speechRecognizer?.startListening(intent)
        } else {
            speechRecognizer?.stopListening()
        }
    }

    // Auto-scroll to newest message
    LaunchedEffect(messages.size) {
        if (messages.isNotEmpty()) listState.animateScrollToItem(messages.lastIndex)
    }

    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    Scaffold(
        modifier = Modifier.imePadding(),
        containerColor = FaithFeedColors.BackgroundPrimary,
        topBar = {
            StudyPartnerTopBar(
                isMuted = isMuted,
                isSpeaking = isSpeaking,
                onMuteToggle = { viewModel.toggleMute() },
                onVoiceSettings = { viewModel.toggleVoiceSettings() },
                onNewConversation = { viewModel.newConversation() },
                onBack = { navController.popBackStack() }
            )
        }
    ) { paddingValues ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(paddingValues)
        ) {
            // ── Message list ───────────────────────────────────────────────────
            LazyColumn(
                state = listState,
                modifier = Modifier
                    .weight(1f)
                    .fillMaxWidth(),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                // Theological disclosure banners — shown above messages when lanes detected
                item(key = "disclosure_banner") {
                    TheologicalDisclosureBanner(
                        lanes = detectedLanes,
                        onDismiss = viewModel::dismissLane
                    )
                }

                items(messages, key = { it.id }) { message ->
                    ChatMessageBubble(
                        message = message,
                        onShareInternal = { navController.navigate(Route.CreatePost) },
                        onAddToPrayerWall = { navController.navigate(Route.CreatePrayer) },
                        onAddToNotes = { navController.navigate(Route.NoteDetail("new")) },
                        onAddToStudyPlan = { navController.navigate(Route.CustomStudyPlan) }
                    )
                }
                if (isLoading) {
                    item {
                        Row(
                            modifier = Modifier.padding(start = 4.dp, top = 4.dp),
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Icon24(Icons.Outlined.Psychology, FaithFeedColors.GoldAccent)
                            Spacer(Modifier.width(8.dp))
                            ThinkingDots()
                        }
                    }
                }
            }

            // ── Input bar ──────────────────────────────────────────────────────
            Surface(
                color = FaithFeedColors.BackgroundSecondary,
                modifier = Modifier.fillMaxWidth()
            ) {
                Column(modifier = Modifier.padding(horizontal = 16.dp, vertical = 12.dp)) {
                    if (isListening) {
                        Text(
                            text = if (inputText.isNotBlank()) inputText else "Listening…",
                            style = Typography.bodySmall,
                            color = FaithFeedColors.GoldAccent,
                            fontStyle = if (inputText.isBlank()) FontStyle.Italic else FontStyle.Normal,
                            modifier = Modifier.padding(bottom = 8.dp)
                        )
                    }
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        // Mic button with pulse animation
                        MicButton(
                            isListening = isListening,
                            isProcessing = isLoading,
                            onClick = {
                                val hasPermission = ContextCompat.checkSelfPermission(
                                    context, Manifest.permission.RECORD_AUDIO
                                ) == PackageManager.PERMISSION_GRANTED
                                if (hasPermission) {
                                    viewModel.onMicTap()
                                } else {
                                    permissionLauncher.launch(Manifest.permission.RECORD_AUDIO)
                                }
                            }
                        )
                        Spacer(Modifier.width(8.dp))
                        OutlinedTextField(
                            value = inputText,
                            onValueChange = { inputText = it },
                            modifier = Modifier.weight(1f),
                            placeholder = {
                                Text("Ask about Scripture…", color = FaithFeedColors.TextTertiary)
                            },
                            keyboardOptions = KeyboardOptions(imeAction = ImeAction.Send),
                            keyboardActions = KeyboardActions(
                                onSend = {
                                    viewModel.sendMessage(inputText)
                                    inputText = ""
                                    focusManager.clearFocus()
                                }
                            ),
                            colors = OutlinedTextFieldDefaults.colors(
                                focusedBorderColor = FaithFeedColors.GoldAccent,
                                unfocusedBorderColor = FaithFeedColors.GlassBorder,
                                focusedTextColor = FaithFeedColors.TextPrimary,
                                unfocusedTextColor = FaithFeedColors.TextPrimary,
                                focusedContainerColor = FaithFeedColors.GlassBackground,
                                unfocusedContainerColor = FaithFeedColors.GlassBackground
                            ),
                            shape = RoundedCornerShape(24.dp),
                            maxLines = 4,
                            enabled = !isListening
                        )
                        Spacer(Modifier.width(8.dp))
                        IconButton(
                            onClick = {
                                viewModel.sendMessage(inputText)
                                inputText = ""
                                focusManager.clearFocus()
                            },
                            enabled = inputText.isNotBlank() && !isLoading && !isListening,
                            colors = IconButtonDefaults.iconButtonColors(
                                contentColor = FaithFeedColors.GoldAccent,
                                disabledContentColor = FaithFeedColors.TextTertiary
                            )
                        ) {
                            androidx.compose.material3.Icon(Icons.AutoMirrored.Outlined.Send, contentDescription = "Send")
                        }
                    }
                }
            }
        }

        // ── Voice settings bottom sheet ────────────────────────────────────────
        if (showVoiceSettings) {
            ModalBottomSheet(
                onDismissRequest = { viewModel.toggleVoiceSettings() },
                sheetState = sheetState,
                containerColor = FaithFeedColors.BackgroundSecondary
            ) {
                VoiceSettingsSheet(
                    selectedVoice = selectedVoice,
                    onVoiceSelect = { voice ->
                        viewModel.setVoice(voice)
                        scope.launch {
                            sheetState.hide()
                            viewModel.toggleVoiceSettings()
                        }
                    }
                )
            }
        }
    }
}

// ── Top bar ────────────────────────────────────────────────────────────────────

@Composable
private fun StudyPartnerTopBar(
    isMuted: Boolean,
    isSpeaking: Boolean,
    onMuteToggle: () -> Unit,
    onVoiceSettings: () -> Unit,
    onNewConversation: () -> Unit,
    onBack: () -> Unit
) {
    Surface(
        color = FaithFeedColors.BackgroundSecondary,
        modifier = Modifier.fillMaxWidth()
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .statusBarsPadding()
                .padding(horizontal = 4.dp, vertical = 8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            IconButton(onClick = onBack) {
                androidx.compose.material3.Icon(
                    imageVector = Icons.AutoMirrored.Filled.ArrowBack,
                    contentDescription = "Back",
                    tint = FaithFeedColors.TextPrimary
                )
            }
            Text(
                text = "AI Study Partner",
                style = Typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                color = FaithFeedColors.TextPrimary,
                modifier = Modifier.weight(1f)
            )
            // Speaking indicator
            if (isSpeaking) {
                androidx.compose.material3.Icon(
                    imageVector = Icons.Outlined.GraphicEq,
                    contentDescription = "Speaking",
                    tint = FaithFeedColors.GoldAccent,
                    modifier = Modifier.size(20.dp)
                )
                Spacer(Modifier.width(4.dp))
            }
            // Mute toggle
            IconButton(onClick = onMuteToggle) {
                androidx.compose.material3.Icon(
                    imageVector = if (isMuted) Icons.AutoMirrored.Outlined.VolumeOff else Icons.AutoMirrored.Outlined.VolumeUp,
                    contentDescription = if (isMuted) "Unmute" else "Mute",
                    tint = if (isMuted) FaithFeedColors.TextTertiary else FaithFeedColors.TextPrimary
                )
            }
            // Voice selector
            IconButton(onClick = onVoiceSettings) {
                androidx.compose.material3.Icon(
                    imageVector = Icons.Outlined.RecordVoiceOver,
                    contentDescription = "Voice settings",
                    tint = FaithFeedColors.TextPrimary
                )
            }
            // New conversation
            IconButton(onClick = onNewConversation) {
                androidx.compose.material3.Icon(
                    imageVector = Icons.Outlined.AddCircleOutline,
                    contentDescription = "New conversation",
                    tint = FaithFeedColors.TextPrimary
                )
            }
        }
    }
}

// ── Mic button ─────────────────────────────────────────────────────────────────

@Composable
private fun MicButton(
    isListening: Boolean,
    isProcessing: Boolean,
    onClick: () -> Unit
) {
    val infiniteTransition = rememberInfiniteTransition(label = "mic_pulse")
    val pulseScale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 1.18f,
        animationSpec = infiniteRepeatable(
            animation = tween(700, easing = EaseInOut),
            repeatMode = RepeatMode.Reverse
        ),
        label = "pulse_scale"
    )

    Box(
        contentAlignment = Alignment.Center,
        modifier = Modifier
            .size(48.dp)
            .scale(if (isListening) pulseScale else 1f)
    ) {
        Surface(
            shape = CircleShape,
            color = when {
                isListening -> FaithFeedColors.GoldAccent
                isProcessing -> FaithFeedColors.BackgroundSecondary
                else -> FaithFeedColors.GlassBackground
            },
            modifier = Modifier.size(48.dp)
        ) {
            Box(contentAlignment = Alignment.Center) {
                IconButton(onClick = onClick, enabled = !isProcessing) {
                    androidx.compose.material3.Icon(
                        imageVector = when {
                            isListening -> Icons.Default.Stop
                            else -> Icons.Default.Mic
                        },
                        contentDescription = if (isListening) "Stop listening" else "Start listening",
                        tint = when {
                            isListening -> FaithFeedColors.BackgroundPrimary
                            isProcessing -> FaithFeedColors.TextTertiary
                            else -> FaithFeedColors.GoldAccent
                        }
                    )
                }
            }
        }
    }
}

// ── Message bubble ─────────────────────────────────────────────────────────────

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun ChatMessageBubble(
    message: AIMessage,
    onShareInternal: (String) -> Unit = {},
    onAddToPrayerWall: (String) -> Unit = {},
    onAddToNotes: (String) -> Unit = {},
    onAddToStudyPlan: (String) -> Unit = {},
) {
    val isUser = message.role == "user"
    var showMenu by remember { mutableStateOf(false) }
    val clipboardManager = LocalClipboardManager.current
    val context = LocalContext.current

    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = if (isUser) Arrangement.End else Arrangement.Start,
        verticalAlignment = Alignment.Top
    ) {
        if (!isUser) {
            Box(
                modifier = Modifier
                    .size(32.dp)
                    .background(FaithFeedColors.GoldAccent, CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Image(
                    painter = painterResource(R.drawable.negspace_omega),
                    contentDescription = "AI",
                    modifier = Modifier.size(22.dp)
                )
            }
            Spacer(Modifier.width(8.dp))
        }
        Column(
            modifier = Modifier.widthIn(max = 280.dp),
            horizontalAlignment = if (isUser) Alignment.End else Alignment.Start
        ) {
            Box {
                Surface(
                    color = when {
                        message.isError -> FaithFeedColors.BackgroundSecondary.copy(alpha = 0.5f)
                        isUser -> FaithFeedColors.GoldAccent.copy(alpha = 0.2f)
                        else -> FaithFeedColors.BackgroundSecondary
                    },
                    shape = RoundedCornerShape(
                        topStart = 16.dp, topEnd = 16.dp,
                        bottomStart = if (isUser) 16.dp else 4.dp,
                        bottomEnd = if (isUser) 4.dp else 16.dp
                    ),
                    modifier = Modifier.combinedClickable(
                        onClick = {},
                        onLongClick = { showMenu = true }
                    )
                ) {
                    Text(
                        text = message.content,
                        modifier = Modifier.padding(12.dp),
                        color = when {
                            message.isError -> FaithFeedColors.TextTertiary
                            isUser -> FaithFeedColors.GoldAccent
                            else -> FaithFeedColors.TextPrimary
                        },
                        style = Typography.bodyLarge,
                        fontFamily = Nunito
                    )
                }
                DropdownMenu(
                    expanded = showMenu,
                    onDismissRequest = { showMenu = false },
                    modifier = Modifier.background(FaithFeedColors.BackgroundSecondary)
                ) {
                    BubbleMenuItem(Icons.Outlined.ContentCopy, "Copy") {
                        clipboardManager.setText(AnnotatedString(message.content))
                        showMenu = false
                    }
                    BubbleMenuItem(Icons.Outlined.Share, "Share") {
                        val intent = Intent(Intent.ACTION_SEND).apply {
                            type = "text/plain"
                            putExtra(Intent.EXTRA_TEXT, message.content)
                        }
                        context.startActivity(Intent.createChooser(intent, "Share via"))
                        showMenu = false
                    }
                    BubbleMenuItem(Icons.Outlined.ChatBubbleOutline, "Post to Feed") {
                        clipboardManager.setText(AnnotatedString(message.content))
                        showMenu = false
                        onShareInternal(message.content)
                    }
                    BubbleMenuItem(Icons.Outlined.VolunteerActivism, "Add to Prayer Wall") {
                        clipboardManager.setText(AnnotatedString(message.content))
                        showMenu = false
                        onAddToPrayerWall(message.content)
                    }
                    BubbleMenuItem(Icons.Outlined.EditNote, "Add to Notes") {
                        clipboardManager.setText(AnnotatedString(message.content))
                        showMenu = false
                        onAddToNotes(message.content)
                    }
                    BubbleMenuItem(Icons.Outlined.MenuBook, "Add to Study Plan") {
                        clipboardManager.setText(AnnotatedString(message.content))
                        showMenu = false
                        onAddToStudyPlan(message.content)
                    }
                }
            }
            // Verse sources shown below assistant bubble
            if (message.sources.isNotEmpty()) {
                Spacer(Modifier.height(6.dp))
                Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                    message.sources.forEach { source ->
                        Surface(
                            color = FaithFeedColors.GoldAccent.copy(alpha = 0.08f),
                            shape = RoundedCornerShape(8.dp)
                        ) {
                            Column(modifier = Modifier.padding(horizontal = 10.dp, vertical = 6.dp)) {
                                Text(
                                    text = source.reference,
                                    style = Typography.labelSmall.copy(fontWeight = FontWeight.Bold),
                                    color = FaithFeedColors.GoldAccent
                                )
                                Text(
                                    text = "\"${source.text}\"",
                                    style = Typography.bodySmall,
                                    color = FaithFeedColors.TextSecondary,
                                    fontFamily = Nunito,
                                    fontStyle = FontStyle.Italic
                                )
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun BubbleMenuItem(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    onClick: () -> Unit
) {
    DropdownMenuItem(
        text = { Text(label, color = FaithFeedColors.TextPrimary, style = Typography.bodyMedium) },
        leadingIcon = {
            androidx.compose.material3.Icon(
                imageVector = icon,
                contentDescription = null,
                tint = FaithFeedColors.TextSecondary,
                modifier = Modifier.size(18.dp)
            )
        },
        onClick = onClick
    )
}

// ── Voice settings sheet ───────────────────────────────────────────────────────

@Composable
private fun VoiceSettingsSheet(
    selectedVoice: String,
    onVoiceSelect: (String) -> Unit
) {
    Column(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp)
            .padding(bottom = 32.dp)
    ) {
        Text(
            text = "Choose a Voice",
            style = Typography.titleMedium.copy(fontWeight = FontWeight.Bold),
            color = FaithFeedColors.TextPrimary
        )
        Spacer(Modifier.height(4.dp))
        Text(
            text = "Powered by OpenAI TTS",
            style = Typography.bodySmall,
            color = FaithFeedColors.TextTertiary
        )
        Spacer(Modifier.height(16.dp))
        TTS_VOICES.forEach { (voiceId, voiceName) ->
            val isSelected = voiceId == selectedVoice
            Surface(
                onClick = { onVoiceSelect(voiceId) },
                color = if (isSelected) FaithFeedColors.GoldAccent.copy(alpha = 0.12f)
                else Color.Transparent,
                shape = RoundedCornerShape(12.dp),
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(vertical = 4.dp)
            ) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 14.dp),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column {
                        Text(
                            text = voiceName,
                            style = Typography.bodyLarge.copy(fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal),
                            color = if (isSelected) FaithFeedColors.GoldAccent else FaithFeedColors.TextPrimary
                        )
                        Text(
                            text = voiceId,
                            style = Typography.bodySmall,
                            color = FaithFeedColors.TextTertiary
                        )
                    }
                    if (isSelected) {
                        androidx.compose.material3.Icon(
                            imageVector = Icons.Outlined.CheckCircle,
                            contentDescription = null,
                            tint = FaithFeedColors.GoldAccent,
                            modifier = Modifier.size(20.dp)
                        )
                    }
                }
            }
            if (voiceId != TTS_VOICES.last().first) {
                HorizontalDivider(
                    color = FaithFeedColors.GlassBorder.copy(alpha = 0.5f),
                    thickness = 0.5.dp
                )
            }
        }
    }
}

// ── Thinking dots animation ────────────────────────────────────────────────────

@Composable
private fun ThinkingDots() {
    val infiniteTransition = rememberInfiniteTransition(label = "dots")
    val alpha by infiniteTransition.animateFloat(
        initialValue = 0.3f,
        targetValue = 1f,
        animationSpec = infiniteRepeatable(
            animation = tween(600, easing = EaseInOut),
            repeatMode = RepeatMode.Reverse
        ),
        label = "dots_alpha"
    )
    Text(
        text = "• • •",
        color = FaithFeedColors.GoldAccent.copy(alpha = alpha),
        style = Typography.bodyMedium,
        fontFamily = Nunito
    )
}

// ── Small helper to avoid verbose import aliases ───────────────────────────────

@Composable
private fun Icon24(imageVector: androidx.compose.ui.graphics.vector.ImageVector, tint: Color) {
    androidx.compose.material3.Icon(
        imageVector = imageVector,
        contentDescription = null,
        tint = tint,
        modifier = Modifier.size(24.dp)
    )
}
