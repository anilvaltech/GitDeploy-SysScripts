# Fetch updates script# version 2.0

# Before running this script the repository should have a default remote (since we are not specifying one by name)
# This happens by default if the repository is cloned.

# Perform fetch on all git repositories immediately beneath the current directory
# This script should therefore be placed at the appropriate location and executed in its current path
# If the deployment repo has a root file named "_WINDOWS-SERVICE-NAME" a windows service of the same name will be stopped before
#  the update is applied, and started afterwards



dir | %{
    echo "-------------------------------------"
    echo "Testing path at: $_"
    if (test-path "$_\.git")
    {
        echo "Performing fetch on : $_"
        cd $_
        
		$gitFetchStatus = ''
		git fetch 2>&1 | Tee-Object -var gitFetchStatus
		
		
		echo "Fetch on $_ completed"
		if  (![system.string]::IsNullOrEmpty($gitFetchStatus))
		{
			echo "Updates were found. Performing a clean, reset and merge"
			
            #Attempt to detect whether this should be a windows service. We must check at this point, before
            # we have updated the working directory, as files may be in use by the service.
            # This means if the service name element has just been added, the next update will cause
            # the service to be stopped and started
            $winService = $null
            $winServiceShouldStart = True
            if (test-path "_WINDOWS-SERVICE-NAME")
			{
                #deployment is a windows service, if installed then stop and start the service
                
                [xml]$serviceDefinition = get-content -path _WINDOWS-SERVICE-NAME
                echo "Deployment repository is a Windows Service with name $service.name."
				
				if  (![system.string]::IsNullOrEmpty($service.name))
				{
                    #get windows service object
                    echo "Retreiving existing service details if any..."
                    $winService = Get-Service "$service.name"
                    if ($winService -eq $null -and $service.autoCreate)
                    {
                        echo "service does not exist and we should create it. Running command..."
                        $currentRepoPath = Get-Location -PSProvider FileSystem
                        if ($service.autoStart)
                        {
                            sc.exe create "$service.name" start= auto binpath=  "$currentRepoPath\$service.binPath"
                        }
                        else
                        {
                            sc.exe create "$service.name" binpath=  "$currentRepoPath\$service.binPath"
                        }
                        
                        #TODO: more decision about whether we should start the service or not?
                        $winServiceShouldStart = True
                        
                        $winService = Get-Service "$service.name"
                        if ($winService -eq $null)
                        {
                            echo "Failed to create service"
                        }
                    }
                    else if ($winService -ne $null -and $winService.status -ne "Running")
                    {
                        #if service was already installed but has been stopped, don't start it later
                        echo "Service exists but was not started, will not attempt to start after update"
                        $winServiceShouldStart = False
                    }

                    if ($winService -ne $null)
                    {
                        if ($winService.status -eq "Running")
                        {
                            echo "Service exists and is Running, stopping service with name '$service.name'"
					        Stop-Service -name $service.name
                        }
                    }
				}
                else
                {
                    echo "Service name was empty"
                }
			}
            else
            {
                echo "Deployment repository was not for a Windows Service"
            }

			echo "Applying changes to build: $_"
			git clean -f -d
			git reset --hard head
			git merge origin/master
			git reset --hard origin/master
            
			if ($?)
			{
				echo "Changed succesfully applied to: $_"
			}
			else
			{
				echo "Failed to apply changes to: $_"
			}

			if ($winService -ne $null -and $winServiceShouldStart -eq True)
			{
                #deployment is a windows service, and we should start it
                echo "Starting service with name $winService.name"
				Start-Service -name $service.name
			}
		}				
		else
		{
			echo "No changes."
		}

        cd ..        
    }
    echo "-------------------------------------"
}