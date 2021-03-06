push-location


#local locations
$gitScriptGitPath = 'e:\git-deploy-get-scripts'
#the following path should exclusively have git folders in it which will be updated as part of the fetch-updates script call below
$gitDeployLocation = 'e:\git-deploy-repos'
$gits = "[your comma-separated list of remote git urls here]"

if (!(test-path $gitDeployLocation))
{
	echo "Created GitDeploy Repository location at $gitDeployLocation"
	mkdir $gitDeployLocation
}

cp fetch-updates.ps1 $gitDeployLocation

#fetch repos if neccessary, or update if they exist already
cd $gitDeployLocation
foreach ($repo in $gits)
{
	$repoLocal = $repo.Replace("/","-")
    if (!(test-path $repoLocal))
    {
		echo "Creating repo $repoLocal"
        git clone ($urlRoot + $repoLocal + ".git") $repoLocal
    }
}

cd $gitDeployLocation
& ".\fetch-updates" + ".ps1"

pop-location
