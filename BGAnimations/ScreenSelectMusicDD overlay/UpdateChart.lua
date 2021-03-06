local difficulties = {
	'Difficulty_Beginner',
	'Difficulty_Easy',
	'Difficulty_Medium',
	'Difficulty_Hard',
	'Difficulty_Challenge',
	'Difficulty_Edit',
}

local difficultyToIndex={}
for k,v in pairs(difficulties) do
   difficultyToIndex[v]=k
end

local EasierDifficulty
local HarderDifficulty

local curDifficultyIndices = {}

local function GetStartingDifficultyIndex(playerNumber)
	local curSteps = GAMESTATE:GetCurrentSteps(playerNumber)

	if curSteps ~= nil then
		local difficulty = curSteps:GetDifficulty()
		local index = difficultyToIndex[difficulty]
		if index ~= nil then
			return index
		end
	end

	local difficulty = DDStats.GetStat(playerNumber, 'LastDifficulty')

	if difficulty ~= nil then
		local index = difficultyToIndex[difficulty]
		
		if index ~= nil then
			return index
		end
	end

	return 5
end

local function SetChart(playerNum, steps)
	curDifficultyIndices[playerNum] = difficultyToIndex[steps:GetDifficulty()]
	GAMESTATE:SetCurrentSteps(playerNum, steps)
	MESSAGEMAN:Broadcast('CurrentStepsChanged', {playerNum=playerNum, steps=steps})
end

local function UpdateChart(playerNum, difficultyChange)
	local song = GAMESTATE:GetCurrentSong()
	if song == nil then
		return
	end

	local stepses = SongUtil.GetPlayableSteps(song)
	if #stepses == 0 then
		return
	end

	-- If we're sorted by difficulty and difficultyChange == 0,
	-- try to keep the same meter
	if GetMainSortPreference() == 6 and difficultyChange == 0 then
		local targetMeter = NameOfGroup

		local oldDifficulty = difficulties[curDifficultyIndices[playerNum]];
		local matchingSteps = nil
		-- Check for meter AND difficulty match
		for steps in ivalues(stepses) do
			if GetStepsDifficultyGroup(steps) == targetMeter and steps:GetDifficulty() == oldDifficulty then
				matchingSteps = steps
				break
			end
		end

		if matchingSteps == nil then
			for steps in ivalues(stepses) do
				if GetStepsDifficultyGroup(steps) == targetMeter then
					matchingSteps = steps
					break
				end
			end
		end

		if matchingSteps ~= nil then
			SetChart(playerNum, matchingSteps)
			return
		end
	end

	local oldDifficultyIndex = curDifficultyIndices[playerNum]

	if oldDifficultyIndex == nil then
		oldDifficultyIndex = GetStartingDifficultyIndex(playerNum)
	end

	local selectedSteps = nil

	local editCount = 0

	for steps in ivalues(stepses) do
		local stepsDifficulty = steps:GetDifficulty()
		local stepsDifficultyIndex = difficultyToIndex[stepsDifficulty]

		if stepsDifficulty == 'Difficulty_Edit' then
			stepsDifficultyIndex = stepsDifficultyIndex + editCount
			editCount = editCount + 1
		end

		if difficultyChange > 0 then
			isValid = stepsDifficultyIndex > oldDifficultyIndex
		elseif difficultyChange < 0 then
			isValid = stepsDifficultyIndex < oldDifficultyIndex
		else
			isValid = true
		end
		if isValid then
			if selectedSteps == nil then
				selectedSteps = steps
			else
				local selectedDifficultyIndex = difficultyToIndex[selectedSteps:GetDifficulty()]
				local selectedDifference = math.abs(selectedDifficultyIndex-oldDifficultyIndex)
				local stepsDifference = math.abs(stepsDifficultyIndex-oldDifficultyIndex)

				if stepsDifference < selectedDifference then
					selectedSteps = steps
				end
			end
		end
	end

	if selectedSteps ~= nil then
		if EasierDifficulty then
			SOUND:PlayOnce( THEME:GetPathS("", "_easier.ogg") )
		elseif HarderDifficulty then
			SOUND:PlayOnce( THEME:GetPathS("", "_harder.ogg") )
		end
		SetChart(playerNum, selectedSteps)
	end
end


return {
	UpdateCharts=function()
		for _, playerNum in ipairs(GAMESTATE:GetHumanPlayers()) do
			EasierDifficulty = false
			HarderDifficulty = false
			UpdateChart(playerNum, 0)
		end
	end,
	IncreaseDifficulty=function(playerNum)
		EasierDifficulty = true
		HarderDifficulty = false
		UpdateChart(playerNum, 1)
	end,
	DecreaseDifficulty=function(playerNum)
		EasierDifficulty = false
		HarderDifficulty = true
		UpdateChart(playerNum, -1)
	end,
}