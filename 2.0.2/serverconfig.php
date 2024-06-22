<?php

// Check if at least one argument is provided
if ($argc < 4) {
    echo "Usage: php script.php <accServerIP> <gameServerIP> <gameDirPath>\n";
    exit(1);
}

function getMac($ip){
    $default = "00-0C-09-BD-F9-24";
    // Define the pattern to match the MAC address
    $pattern = '/(?:ether|HWaddr)\s+([0-9a-fA-F:]+)/';

    exec("/sbin/ifconfig -a", $output);

    // Search for the line containing 'HWaddr' or 'ether' (depends on the system)
    $found = false;
    foreach ($output as $line) {
        if (strpos($line, $ip) !== false){
            $found = true;
        }
        if ($found && strpos($line, 'ether') !== false) {
            // Perform the regular expression match
            if (preg_match($pattern, $line, $matches)) {
                // Extracted MAC address is in $matches[1]
                return strtoupper(str_replace(":","-",$matches[1]));
            } else {
                // If no match is found, return false or handle it accordingly
                return $default;
            }            
        }
    }
    return $default;
}

$acc = $argv[1];
$game = $argv[2];
$gamePath = $argv[3];
$mac = getMac($game);
$currentScriptDir = dirname(__FILE__);

$files = [
    "$currentScriptDir/gameconfigs/bishop.cfg" => "$gamePath/gateway/bishop.cfg", 
    "$currentScriptDir/gameconfigs/goddess.cfg" => "$gamePath/gateway/goddess.cfg", 
    "$currentScriptDir/gameconfigs/relay_config.ini" => "$gamePath/gateway/s3relay/relay_config.ini", 
    "$currentScriptDir/gameconfigs/servercfg.ini" => "$gamePath/server1/servercfg.ini"];
    
foreach($files as $k=>$v){
    $c = file_get_contents($k);
    $c = str_replace("ACCSERVERIP", $acc, $c);
    $c = str_replace("GAMESERVERIP", $game, $c);
    $c = str_replace("GAMEMACADDR", $mac, $c);
    
    file_put_contents($v, $c);
}

echo "$mac $game $acc";