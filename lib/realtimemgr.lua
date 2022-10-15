-- controls.lua
--
-- Handle real-time management
-- i.e. loading / saving of patches and of parameter status
--

local rtMgr = {}

--- @public controls.loadPatch remove previous patch, load and init a new patch based on its relative path
function rtMgr.loadPatch(patchName)
	lovjUnrequire(currentPatchName)
	currentPatchName = patchName
	patch = lovjRequire(currentPatchName, lick.PATCH_RESET)
	patch.init()
end

return rtMgr