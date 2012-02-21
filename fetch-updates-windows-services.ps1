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
			#attempt to detect whether this should be a windows service. We must check at this point, before
            # we have updated the working directory, as files may be in use by the service.
            # This means if the service name element has just been added, the next update will cause
            # the service to be stopped and started
            if (test-path "_WINDOWS-SERVICE-NAME")
			{
                #deployment is a windows service, if installed then stop and start the service
                
                $serviceName = get-content -path _WINDOWS-SERVICE-NAME
                echo "Service found with name $serviceName, stopping service..."
				
				if  (![system.string]::IsNullOrEmpty($serviceName))
				{
					Stop-Service -name $serviceName
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

			if (test-path "_WINDOWS-SERVICE-NAME")
			{
                #TODO: detect if service was started (or if service is automatic), and only start the service if so
                $serviceName = get-content -path _WINDOWS-SERVICE-NAME
                echo "Starting service with name $serviceName"
				#deployment is a windows service, start the service since we stopped it above
				
				if  (![system.string]::IsNullOrEmpty($serviceName))
				{
					Start-Service -name $serviceName
				}
                else
                {
                    echo "Service name was emtpy"
                }
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