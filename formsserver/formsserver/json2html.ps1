param (
    [string] $jsonfile,
    [string] $htmlfile,
    [string] $ip,
    [string] $usr
)

[Reflection.Assembly]::LoadFile("C:\scripts\nodejs\formsserver\measurestring.dll");

$sb = [System.Text.StringBuilder]::new();
function buildString($s) {
    [void]$sb.Append($s);
}

$json = Get-Content $jsonfile;

$jobj = ($json | ConvertFrom-Json);

$maxy = 0;

foreach ($j in $jobj) {
    if ($null -ne $j.normalfont) {
        $normalfont = $j.normalfont;
        $normalsize = $j.normalsize;
        $wunit = [int]([measurestring]::fontWidth($normalfont, $normalsize, "00" / 2));
        $hunit = 1.05;
        $adjunit = 1.01;
        $title = $j.title;
        $description = $j.description;
        $approval = $j.approval;
    }
    if ($null -ne $j.x) {
        if ($j.y -gt $maxy) {
            $maxy = $j.y;
        }
        if ($null -ne $j.value -or $null -ne $j.type) {
            buildString ('<div style="position: absolute; left:{0}px; top: {1}px; font-size: {2}px; font-family: {3};' -f [int]($j.x * $wunit * $adjunit), [int]($j.y * $hunit), $j.fontSize, $j.fontName);
            buildString ('width: {0}px; height: {1}px;' -f [int]($j.width * $wunit), [int]$j.height);

            if ($null -ne $j.fontBold) {
                buildString 'font-weight: bold;';
            }
            if ($null -ne $j.fontItalic) {
                buildString 'font-style: italic;';
            }
            if ($null -ne $j.fontColor) {
                buildString ('color: #{0};' -f $j.fontColor);
            }
            if ($null -ne $j.interiorColor) {
                buildString ('background-color: #{0};' -f $j.interiorColor);
            }
            if ($null -ne $j.borderTopLineStyle) {
                buildString ('border-top-style: {0};' -f @(Switch ($j.borderTopLineStyle) { '1' {'solid'} '-4115' {'dotted'} '-4118' {'dashed'} }));
                buildString ('border-top-width: {0};' -f @(Switch ($j.borderTopWeight) { '1' {'1px'} '2' {'2px'} '-4138' {'3px'} '4' {'4px'}}));
                buildString ('border-top-color: #{0};' -f $j.borderTopColor);
            }
            if ($null -ne $j.borderBottomLineStyle) {
                buildString ('border-bottom-style: {0};' -f @(Switch ($j.borderBottomLineStyle) { '1' {'solid'} '-4115' {'dotted'} '-4118' {'dashed'} }));
                buildString ('border-bottom-width: {0};' -f @(Switch ($j.borderBottomWeight) { '1' {'1px'} '2' {'2px'} '-4138' {'3px'} '4' {'4px'}}));
                buildString ('border-bottom-color: #{0};' -f $j.borderBottomColor);
            }
            if ($null -ne $j.borderLeftLineStyle) {
                buildString ('border-left-style: {0};' -f @(Switch ($j.borderLeftLineStyle) { '1' {'solid'} '-4115' {'dotted'} '-4118' {'dashed'} }));
                buildString ('border-left-width: {0};' -f @(Switch ($j.borderLeftWeight) { '1' {'1px'} '2' {'2px'} '-4138' {'3px'} '4' {'4px'}}));
                buildString ('border-left-color: #{0};' -f $j.borderLeftColor);
            }
            if ($null -ne $j.borderRightLineStyle) {
                buildString ('border-right-style: {0};' -f @(Switch ($j.borderRightLineStyle) { '1' {'solid'} '-4115' {'dotted'} '-4118' {'dashed'} }));
                buildString ('border-right-width: {0};' -f @(Switch ($j.borderRightWeight) { '1' {'1px'} '2' {'2px'} '-4138' {'3px'} '4' {'4px'}}));
                buildString ('border-right-color: #{0};' -f $j.borderRightColor);
            }

            if ($null -ne $j.type) {
                if ($j.type -eq 'textarea') {
                    buildString ('"><textarea id={0} name={0} rows={1} cols={2} style="font-family:inherit;"></textarea></div>' -f ($j.id, [int]($j.height / ($normalsize * 1.5)), [int]$j.width));
                } else {
                    $size = [int]($j.width * $wunit);
                    if ($j.type -eq 'date') {
                        buildString ('"><input id={0} name={0} type="{1}" placeholder="mm/dd/yyyy" style="width: {2}px; height: {3}px; font-family:inherit;"></div>' -f ($j.id, $j.type, $size, [int]$j.height));
                    } else {
                        buildString ('"><input id={0} name={0} type="{1}" style="width: {2}px; height: {3}px; font-family:inherit;"></div>' -f ($j.id, $j.type, $size, [int]$j.height));
                    }
                }
            } else {
                buildString ('">{0}</div>' -f $j.value);
            }

            buildString "`n";
        }
        if ($null -ne $j.validation) {
            buildString ('<div style="position: absolute; left:{0}px; top: {1}px; font-size: {2}px; font-family: {3};' -f [int]($j.x * $wunit * $adjunit), [int]($j.y * $hunit), $j.fontSize, $j.fontName);
            buildString ('"><select id={0} name={0} style="width: {1}px; height: {2}px; cont-family:inherit;">' -f $j.id, [int]($j.width * $wunit), [int]$j.height);
            buildString "`n";
            $j.validation.GetEnumerator() | ForEach-Object {
                buildString ('<option value="{0}">{1}</option>' -f $_, $_);
                buildString "`n";
            }
            buildString '</select>';
            buildString "`n";
            buildString '</div>';
            buildString "`n";
        }
        if ($null -ne $j.formula) {
            buildString ('<div style="position: absolute; left:{0}px; top: {1}px; font-size: {2}px; font-family: {3};' -f [int]($j.x * $wunit * $adjunit), [int]($j.y * $hunit), $j.fontSize, $j.fontName);
            $size = [int]($j.width * $wunit);
            buildString ('"><input id={0} name={0} type=text style="width: {2}px; height: {3}px; font-family:inherit;" class="formula" formula=''{4}''></div>' -f ($j.id, $j.type, $size, [int]$j.height, $j.formula));
            buildString "`n";
        }
    }
}

$html = $sb.ToString();

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

