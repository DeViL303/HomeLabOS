function Launch()
	LoadLibrary("Platform")
	LoadLibrary("Portable")
	LoadLibrary("Object")

	if Platform.IsPlatformScriptActive(2) then
     Platform.KillPlatformScript(2)
else
end
	Portable.Destroy()
end
Launch()
Launch = nil