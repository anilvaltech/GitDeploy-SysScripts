# Fetch updates script# version 1.3

# Before running this script the repository should have a default remote (since we are not specifying one by name)
# This happens by default if the repository is cloned.

# Perform fetch on all git repositories immediately beneath the current directory
# This script should therefore be placed at the appropriate location and executed in its current path


dir | %{
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
		}				
		else
		{
			echo "No changes."
		}

        cd ..        
    }
}