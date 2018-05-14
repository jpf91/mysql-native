import std.file;
import std.process;

void main()
{
	auto haveRdmd = executeShell("rdmd --help").status == 0;
	if(!haveRdmd)
	{
		auto dmdZip = "dmd.2.076.0."~environment["TRAVIS_OS_NAME"]~".zip";
		spawnShell("http://downloads.dlang.org/releases/2017/"~dmdZip).wait;
		spawnShell("unzip -d local-dmd "~dmdZip).wait;
	}

	// MySQL is not installed by default on OSX build agents
	if(environment["TRAVIS_OS_NAME"] == "osx")
	{
		spawnShell("brew update").wait;
		spawnShell("brew install mysql && brew services start mysql").wait;
	}

	// If an alternate dub.selections.json was requested, use it.
	copy("dub.selections."~environment["DUB_SELECT"]~".json", "dub.selections.json");
	copy("examples/homePage/dub.selections."~environment["DUB_SELECT"]~".json", "examples/homePage/dub.selections.json");

	if(environment["DUB_UPGRADE"])
	{
		// Update all dependencies
		spawnShell("dub upgrade").wait;
		chdir("examples/homePage");
		spawnShell("dub upgrade").wait;
		chdir("../..");
	}
	else
	{
		// Don't upgrade dependencies.
		// But download & resolve deps now so intermittent failures are more likely
		// to be correctly marked as "job error" rather than "tests failed".
		spawnShell("dub upgrade --missing-only").wait;
		chdir("examples/homePage");
		spawnShell("dub upgrade --missing-only").wait;
		chdir("../..");
	}

	// Setup DB
	spawnShell(`mysql -u root -e 'SHOW VARIABLES LIKE "%version%";'`).wait;
	spawnShell(`mysql -u root -e 'CREATE DATABASE mysqln_testdb;'`).wait;
	write("testConnectionStr.txt", "host=127.0.0.1;port=3306;user=root;pwd=;db=mysqln_testdb");
}
