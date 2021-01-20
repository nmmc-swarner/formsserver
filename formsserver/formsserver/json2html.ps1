param (
    [string] $jsonfile,
    [string] $htmlfile,
    [string] $ip,
    [string] $usr
)

[Reflection.Assembly]::LoadFile("C:\scripts\nodejs\formsserver\measurestring.dll");

function ConvertTo-Hashtable { 
    param ( 
        [Parameter(  
            Position = 0,   
            Mandatory = $true,   
            ValueFromPipeline = $true,  
            ValueFromPipelineByPropertyName = $true  
        )] [object] $psCustomObject 
    );
    $output = @{}; 
    $psCustomObject | Get-Member -MemberType *Property | % {
        $output.($_.name) = $psCustomObject.($_.name); 
    } 
    return  $output;
}

$json = Get-Content $jsonfile;

$jobj = ($json | ConvertFrom-Json);

# text input is measured in em. 1em == 11px

# need to add empty elements to fill the page for the popups  ................................ TO DO

$maxy = 0;

foreach ($j in $jobj) {
    $h = $j | ConvertTo-Hashtable

    if ($null -ne $h['normalfont']) {
        $normalfont = $h['normalfont'];
        $normalsize = $h['normalsize'];
        $wunit = [int]([measurestring]::fontWidth($normalfont, $normalsize, "00") / 2);
        $title = $h['title'];
        $description = $h['description'];
        $approval = $h['approval'];
    }
    if ($null -ne $h['x']) {
        if ($h['y'] -gt $maxy) {
            $maxy = $h['y'];
        }
        if ($null -ne $h['value'] -or $null -ne $h['type']) {
            $html += '<div style="position: fixed; left:{0}px; top: {1}px; font-size: {2}px; font-family: {3};' -f [int]($h['x'] * $wunit), [int]$h['y'], $h['fontSize'], $h['fontName'];

            if ($null -ne $h['fontBold']) {
                $html += 'font-weight: bold;'
            }
            if ($null -ne $h['fontColor']) {
                $html += ('color: #{0};' -f $h['fontColor'])
            }
            if ($null -ne $h['interiorColor']) {
                $html += ('background-color: #{0};' -f $h['interiorColor'])
            }

            # <textarea name="message" rows="10" cols="30"> textarea TAG instead of INPUT

            if ($null -ne $h['type']) {
                if ($h['type'] -eq 'textarea') {
                    $html += '"><textarea id={0} name={0} rows={1} cols={2} style="font-family:inherit;"></textarea></div>' -f ($h['id'], [int]($h['height'] / ($normalsize * 1.5)), [int]$h['width']);
                } else {
                    $size = [int]($h['width'] * $wunit);
                    if ($h['type'] -eq 'date') {
                        $html += '"><input id={0} name={0} type="{1}" placeholder="mm/dd/yyyy" style="width: {2}px; height: {3}px; font-family:inherit;"></div>' -f ($h['id'], $h['type'], $size, [int]$h['height']);
                    } else {
                        $html += '"><input id={0} name={0} type="{1}" style="width: {2}px; height: {3}px; font-family:inherit;"></div>' -f ($h['id'], $h['type'], $size, [int]$h['height']);
                    }
                }
            } else {
                $html += '">{0}</div>' -f $h['value'];
            }

            $html += "`n";
        }
        if ($null -ne $h['validation']) {
            $html += '<div style="position: fixed; left:{0}px; top: {1}px; font-size: {2}px; font-family: {3};' -f [int]($h['x'] * $wunit), [int]$h['y'], $h['fontSize'], $h['fontName'];
            $html += '"><select id={0} name={0} style="width: {1}px; height: {2}px;">' -f $h['id'], [int]($h['width'] * $wunit), [int]$h['height'];
            $html += "`n";
            $h['validation'].GetEnumerator() | % {
                $html += ('<option value="{0}">{1}</option>' -f $_, $_);
                $html += "`n";
            }
            $html += '</select>';
            $html += "`n";
            $html += '</div>';
            $html += "`n";
        }
        if ($null -ne $h['formula']) {
            $html += '<div style="position: fixed; left:{0}px; top: {1}px; font-size: {2}px; font-family: {3};' -f [int]($h['x'] * $wunit), [int]$h['y'], $h['fontSize'], $h['fontName'];
            $size = [int]($h['width'] * $wunit);
            $html += '"><input id={0} name={0} type=text style="width: {2}px; height: {3}px; font-family:inherit;" class="formula" formula=''{4}''></div>' -f ($h['id'], $h['type'], $size, [int]$h['height'], $h['formula']);

            $html += "`n";
        }
    }
}

if ($ip -eq '::1') {
    $ip -eq '127.0.0.1'
}
else {
    $ip -match '(?<ip>[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3})';
    $ip = $Matches.ip;
}

# get the current Active session name
$sessions = (query session /server:$ip).split("`n");
for ($i = 1; $i -lt $sessions.length; $i++) {
    Write-Host ("|" + $sessions[$i] + "|");
    if ($sessions[$i] -like '*Active*') {
        $sessions[$i] -match '(?<SessionName>[a-z0-9-#]+)';
        break;
    }
}

# get the user on the session
$out = (query user $Matches.SessionName /server:$ip).split("`n");
$out[1] -match '(?<ADuser>[a-z0-9]+)\s+(?<session>[a-z0-9-#]+).+\s(?<logontime>[0-9]{1,2}\/[0-9]{1,2}\/[0-9]{4}\s[0-9]{1,2}:[0-9]{2}\s[AP]M)';

Write-Host $Matches.ADuser;
Write-Host $Matches.session;
Write-Host $Matches.logontime;

$user = $Matches.ADuser;
$session = $Matches.session;
$logontime = $Matches.logontime;

# get most recent rdp connection time from the event log
if ($session -like '*rdp-tcp#*') {
    $ago = (Get-Date) - (New-TimeSpan -Day 2);
    $logname = 'Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'; #25 - session reconnected
    $messages = Get-WinEvent -ComputerName $ip -LogName $logname | Where-Object { $_.TimeCreated -ge $ago -and $_.Id -eq 25};
    foreach ($_ in $messages) {
        Write-Host $_.TimeCreated;
        $logontime = $_.TimeCreated;
        break;
    }
}

$aduser = Get-ADUser $Matches.ADuser -Properties * | Select-Object Name, EmailAddress
if ($null -eq $aduser.Name) {
    $ADn = "Please provide a valid user name";
    $ADe = "Please provide a valid email address";
    $ADs = "";
} else {
    $ADn = $aduser.Name;
    $ADe = $aduser.EmailAddress;
    $ADs = ("{0} {1} {2} {3}" -f $ip, $user, $session, $logontime);
}

((Get-Content './form.html') -replace ('title4930cd57-0961-4f30-92d7-4eb5c3e8381b', $title) `
-replace ('description50457d64-1baa-480b-905c-b59dd8086dde', $description) `
-replace ('approval7d0aac5d-47c2-4e0c-8bc4-23761efa7a0e', $approval) `
-replace ('ADn7ae5aea0-4552-4d6e-97c6-81de833c99cc', $ADn) `
-replace ('ADe181dde0b-974d-40ab-ae86-5cdd60008530', $ADe) `
-replace ('formhtmld8ee24e6-747a-4bda-93f0-090d7ee7d675', $html)) `
-replace ('ADs157fddd5-969a-4660-8283-e6b99ab5906b', $ADs) | Set-Content $htmlfile;

