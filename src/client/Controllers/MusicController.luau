--!strict
-- MusicController: Phase-based background music with crossfade transitions,
-- audio ducking during phone/dialogue events, and taskbar mute toggle.

local SoundService = game:GetService("SoundService")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = require(Shared:WaitForChild("Config"))

local MusicController = {}

-- Track assignments per game phase
local PHASE_TRACKS: { [string]: string } = {
	Lobby = "rbxassetid://115638035040625", -- West Coast Type Beat (menu)
	InShift = "rbxassetid://81027425424909", -- Lowrider Bounce (on the clock)
	Summary = "rbxassetid://111281628096922", -- Late Night Smooth Jazz Synth (clock off)
}

local DEFAULT_VOLUME = 0.35
local DUCKED_VOLUME = 0.10
local FADE_TIME = 1.0

local currentSound: Sound? = nil
local currentPhase: string = ""
local isMuted: boolean = false
local isDucked: boolean = false
local speakerWaves: { Frame } = {}
local gameStateSync: RemoteEvent? = nil

-- Create a looping Sound parented to SoundService
local function createSound(soundId: string): Sound
	local sound = Instance.new("Sound")
	sound.SoundId = soundId
	sound.Volume = 0
	sound.Looped = true
	sound.Name = "BGM"
	sound.Parent = SoundService
	return sound
end

-- Smooth tween volume
local function tweenVolume(sound: Sound, targetVolume: number, duration: number)
	local tween = TweenService:Create(
		sound,
		TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ Volume = targetVolume }
	)
	tween:Play()
	return tween
end

-- Get the appropriate volume based on mute/duck state
local function getTargetVolume(): number
	if isMuted then
		return 0
	end
	if isDucked then
		return DUCKED_VOLUME
	end
	return DEFAULT_VOLUME
end

-- Crossfade to a new track for the given phase
function MusicController.transitionTo(phase: string): ()
	local trackId = PHASE_TRACKS[phase]
	if not trackId then
		return
	end
	if phase == currentPhase and currentSound then
		return
	end

	currentPhase = phase

	-- Fade out old track
	if currentSound then
		local oldSound = currentSound
		local fadeOut = tweenVolume(oldSound, 0, FADE_TIME)
		fadeOut.Completed:Connect(function()
			oldSound:Stop()
			oldSound:Destroy()
		end)
	end

	-- Create and fade in new track
	local newSound = createSound(trackId)
	currentSound = newSound
	newSound:Play()
	tweenVolume(newSound, getTargetVolume(), FADE_TIME)
end

-- Duck audio during phone calls / dialogues
function MusicController.duckAudio(duck: boolean): ()
	isDucked = duck
	if currentSound and not isMuted then
		tweenVolume(currentSound, getTargetVolume(), 0.3)
	end
end

-- Toggle mute from taskbar speaker icon
function MusicController.toggleMute(): ()
	isMuted = not isMuted
	if currentSound then
		tweenVolume(currentSound, getTargetVolume(), 0.2)
	end

	-- Update speaker wave visuals
	for _, wave in speakerWaves do
		wave.BackgroundTransparency = if isMuted then 0.7 else 0
	end
end

-- Register the speaker icon waves so we can dim them on mute
function MusicController.registerSpeakerWaves(waves: { Frame }): ()
	speakerWaves = waves
end

function MusicController.init(): ()
	local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
	gameStateSync = remotesFolder:WaitForChild("GameStateSync") :: RemoteEvent
end

function MusicController.start(): ()
	if gameStateSync then
		(gameStateSync :: RemoteEvent).OnClientEvent:Connect(function(state: any)
			if state and state.phase then
				MusicController.transitionTo(state.phase)
			end
		end)
	end

	-- Start with lobby music immediately
	MusicController.transitionTo("Lobby")
end

return MusicController
