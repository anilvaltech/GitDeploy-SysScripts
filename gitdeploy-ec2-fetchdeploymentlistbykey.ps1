#attempt to fetch git-deploy key from instance user-data
$wc = new-object System.Net.WebClient;
try
{
	$gitDeployKey = $wc.DownloadString("http://instance-data/latest/user-data")
}
catch
{
}
if ([system.string]::IsNullOrEmpty($gitDeployKey))
{
	$gitDeployKey = 'gdr2-github' #default
}

#local locations
$gitScriptGitPath = 'e:\git-deploy-get-scripts'
$gitDeployLocation = 'e:\git-deploy-repos'

#git-deploy central server script location (GitHub.com)
$gitDeployServerPath = 'https://[your source git repo with repo lists here]'

push-location
#Fetch updates on git-script-git

if (!(test-path $gitScriptGitPath))
{
	git clone $gitDeployServerPath $gitScriptGitPath
}
else
{
	cd $gitScriptGitPath
	echo "Fetching updates on gitdeploy scripts at $gitScriptGitPath..."
	$gitFetchStatus = ''
		git fetch 2>&1 | Tee-Object -var gitFetchStatus
	if  (![system.string]::IsNullOrEmpty($gitFetchStatus))
	{
		echo "Updates were found. Performing a clean, reset and merge"
		git clean -f -d
		git reset --hard head
		git merge origin/master
	}
	else
	{
		echo "No updates."
	}
}

if (!(test-path $gitDeployLocation))
{
	echo "Created GitDeploy Repository location at $gitDeployLocation"
	mkdir $gitDeployLocation
}

cd $gitScriptGitPath

echo "Running GitDeploy script for key $gitDeployKey"
# Run script
& ".\$gitDeployKey" + ".ps1"