function Launch()
	LoadLibrary("Platform")
	LoadLibrary("Portable")
	LoadLibrary("Object")
	ObjectName = Object.DebugFind("FFFFFFF300000000")
	if Platform.IsPlatformScriptActive(2) then
     Platform.KillPlatformScript(2)
     Platform.ActivatePlatformScript("30303030-30303030-30303030-00000004", 2, "shutdown")
else
		Platform.ActivatePlatformScript("30303030-30303030-30303030-00000004", 2)
end
	Portable.Destroy()
end
Launch()
Launch = nil