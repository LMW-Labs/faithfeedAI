package com.faithfeed.app.ui.screens.games

import androidx.lifecycle.ViewModel
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import javax.inject.Inject

data class ScriptureRef(val ref: String, val text: String)

data class StoryChoice(val text: String, val nextSceneId: String, val faithPoints: Int)

data class StoryScene(
    val id: String,
    val title: String,
    val emoji: String,
    val text: String,
    val scripture: ScriptureRef? = null,
    val choices: List<StoryChoice> = emptyList(),
    val isEnding: Boolean = false,
    val endingMessage: String? = null,
    val endingFaithBonus: Int = 0
)

data class TheWalkState(
    val currentScene: StoryScene,
    val faithPoints: Int = 0,
    val history: List<String> = emptyList(),
    val showScripture: Boolean = false,
    val isComplete: Boolean = false
)

@HiltViewModel
class TheWalkViewModel @Inject constructor() : ViewModel() {

    private val scenes: Map<String, StoryScene> = buildScenesMap()

    private val _state = MutableStateFlow(
        TheWalkState(currentScene = scenes.getValue("intro"))
    )
    val state: StateFlow<TheWalkState> = _state.asStateFlow()

    fun onChoiceSelected(choice: StoryChoice) {
        val current = _state.value
        val nextScene = scenes[choice.nextSceneId] ?: return
        val newPoints = current.faithPoints + choice.faithPoints
        val newHistory = current.history + current.currentScene.id

        _state.value = current.copy(
            currentScene = nextScene,
            faithPoints = newPoints + nextScene.endingFaithBonus,
            history = newHistory,
            showScripture = false,
            isComplete = nextScene.isEnding
        )
    }

    fun onToggleScripture() {
        _state.value = _state.value.copy(showScripture = !_state.value.showScripture)
    }

    fun restart() {
        _state.value = TheWalkState(currentScene = scenes.getValue("intro"))
    }

    fun tierLabel(faithPoints: Int): String = when {
        faithPoints >= 40 -> "Righteous"
        faithPoints >= 20 -> "Faithful"
        else -> "Struggling"
    }

    private fun buildScenesMap(): Map<String, StoryScene> = listOf(
        StoryScene(
            id = "intro",
            title = "A Test of the Heart",
            emoji = "\uD83C\uDFDB\uFE0F",
            text = "You are Joseph, second-in-command of Egypt. Your brothers stand before you seeking grain — the same brothers who sold you into slavery years ago. They do not recognize you. How will you respond?",
            scripture = ScriptureRef(
                ref = "Genesis 42:7",
                text = "When Joseph saw his brothers, he recognized them, but he pretended to be a stranger and spoke roughly to them."
            ),
            choices = listOf(
                StoryChoice("Test their hearts first", "test_hearts", 5),
                StoryChoice("Reveal yourself immediately", "reveal_early", 10)
            )
        ),
        StoryScene(
            id = "test_hearts",
            title = "The Feast",
            emoji = "\uD83C\uDF7D\uFE0F",
            text = "You invite your brothers to feast and seat them in birth order — a detail only family would know. Benjamin, your youngest brother, sits across from you. Your heart aches with longing. Do you test them further?",
            scripture = ScriptureRef(
                ref = "Genesis 43:34",
                text = "Benjamin's portion was five times as much as any of theirs."
            ),
            choices = listOf(
                StoryChoice("Plant the silver cup in Benjamin's sack", "cup_test", 15),
                StoryChoice("Call the feast and reveal yourself now", "reveal_feast", 10)
            )
        ),
        StoryScene(
            id = "cup_test",
            title = "The Cup",
            emoji = "\uD83C\uDF7A",
            text = "Your steward overtakes the brothers on the road and accuses them of theft. They are brought back in shame. Benjamin is to be enslaved as punishment. Judah steps forward with a trembling voice...",
            scripture = ScriptureRef(
                ref = "Genesis 44:16",
                text = "What can we say to my lord? What can we speak? Or how can we clear ourselves?"
            ),
            choices = listOf(
                StoryChoice("Accept Judah's offer to take Benjamin's place", "accept_judah", -20),
                StoryChoice("Stop the test — you've seen enough", "reveal_full", 25)
            )
        ),
        StoryScene(
            id = "reveal_early",
            title = "Too Soon",
            emoji = "\uD83C\uDF05",
            text = "You reveal yourself before the test is complete. Your brothers are stunned but relieved. The reconciliation feels hurried — some questions of the heart remain unanswered. Faith gained: 10",
            isEnding = true,
            endingFaithBonus = 10,
            endingMessage = "Mercy given too quickly sometimes leaves old wounds unhealed."
        ),
        StoryScene(
            id = "reveal_feast",
            title = "Mercy at the Table",
            emoji = "\uD83D\uDD4A\uFE0F",
            text = "At the height of the feast, emotion overwhelms you. You clear the room and weep so loudly the Egyptians hear it. 'I am Joseph!' The room falls silent. Faith gained: 10",
            isEnding = true,
            endingFaithBonus = 10,
            endingMessage = "Restoration came through vulnerability and tears."
        ),
        StoryScene(
            id = "reveal_full",
            title = "The Full Redemption",
            emoji = "\u2728",
            text = "You have seen Judah offer himself as a slave for Benjamin — the very thing your brothers would not do for you. The test is complete. You send everyone out except your brothers. Then you weep. 'I am Joseph your brother, whom you sold into Egypt. But do not be distressed — God sent me here ahead of you.' Faith gained: 25",
            isEnding = true,
            endingFaithBonus = 25,
            endingMessage = "What others meant for evil, God meant for good. — Genesis 50:20"
        ),
        StoryScene(
            id = "accept_judah",
            title = "A Hollow Victory",
            emoji = "\uD83D\uDE14",
            text = "You accept Judah's slavery offer. The test ends, but bitterness lingers in the room. You realize revenge disguised as justice still costs everyone. Faith lost: 20",
            isEnding = true,
            endingFaithBonus = -20,
            endingMessage = "Some victories feel empty the moment they are won."
        )
    ).associateBy { it.id }
}
