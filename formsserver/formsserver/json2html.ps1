<#
param (
    [string] $jsonfile,
    [string] $htmlfile,
    [string] $ip,
    [string] $usr
)
#>

$jsonfile = '\\file01\data\nmmc documents\Scripts\excelToJson\sample.json';
$htmlfile = 'test.html';
$ip = '10.1.2.63';
$usr = 'swarner';

[Reflection.Assembly]::LoadFile("C:\scripts\nodejs\formsserver\measurestring.dll");

$sb = [System.Text.StringBuilder]::new();
function buildString($s) {
    [void]$sb.Append($s);
}

$json = Get-Content $jsonfile;
$jobj = ($json | ConvertFrom-Json);

foreach ($j in $jobj) {
    if ($null -ne $j.normalfont) {
        $normalfont = $j.normalfont;
        $normalsize = $j.normalsize;
        $wunit = [int]([measurestring]::fontWidth($normalfont, $normalsize, "0") * .8);
        $title = $j.title;
        $description = $j.description;
        $approval = $j.approval;
        $preview = $j.preview;
        [int32[]]$wArr = $j.wArr;
        [int32[]]$hArr = $j.hArr;

        $table = New-Object 'object[,]' ($hArr.length + 1), ($wArr.length + 1);

        if ($preview) {
            $table[0,0] = '<td width=5 height=5 style=" color: #A9A9A9; background-color: #e5e4e2;">&#x25e2</td>';

            # table row 0 defines column widths
            for ($c=0; $c -lt $wArr.length; $c++) {
                $table[0, ($c + 1)] = '<td width={0} style="text-align: center; background-color: #e5e4e2;">{1}</td>' -f ($wArr[$c] * $wunit), [char]($c + 65);
            }
            # table column 0 defines row heights
            for ($r=0; $r -lt $hArr.length; $r++) {
                $table[($r + 1), 0] = '<td height={0} style=" background-color: #e5e4e2;">{1}</td>' -f $hArr[$r], ($r + 1);
            }
        } else {
            $table[0,0] = '<td width=5 height=5 style=" color: #A9A9A9; background-color: #ffffff;"></td>';

            # table row 0 defines column widths
            for ($c=0; $c -lt $wArr.length; $c++) {
                $table[0, ($c + 1)] = '<td width={0} style="text-align: center; background-color: #ffffff;"></td>' -f ($wArr[$c] * $wunit), [char]($c + 65);
            }
            # table column 0 defines row heights
            for ($r=0; $r -lt $hArr.length; $r++) {
                $table[($r + 1), 0] = '<td height={0} style=" background-color: #ffffff;"></td>' -f $hArr[$r], ($r + 1);
            }
        }
    } else {
        $sb.Clear();
        if ($preview) {
            buildString '<td class="preview" ';
        } else {
            buildString '<td ';
        }
        
        # add span
        if ($null -ne $j.colspan) {
            if ($j.rowspan -gt 1) {
                $td_height = 0;
                for ($i=$j.row; $i -lt $j.row + $j.rowspan; $i++) {
                    $td_height += $hArr[$i];
                }
            } else {
                $td_height = $hArr[$j.row];
            }
            if ($j.colspan -gt 1) {
                $td_width = 0;
                for ($i=$j.col; $i -lt $j.col + $j.colspan; $i++) {
                    $td_width += $wArr[$i];
                }
            } else {
                $td_width = $wArr[$j.col];
            }
            buildString ('colspan={0} rowspan={1} width={2} height={3} ' -f $j.colspan, $j.rowspan, $td_width, $td_height);
        } else {
            buildString ('height={0} ' -f $hArr[$j.row]);
        }

        # add cell styling
        buildString 'style="';

        if ($null -ne $j.fontName) { buildString (' font-family: {0};' -f $j.fontName); }
        if ($null -ne $j.fontSize) { buildString (' font-size: {0}px;' -f $j.fontSize); }
        if ($null -ne $j.fontBold) { buildString (' font-weight: bold;'); }
        if ($null -ne $j.fontItalic) { buildString (' font-style: italic;'); }
        if ($null -ne $j.fontColor) { buildString (' color: {0};' -f $j.fontColor); }
        if ($null -ne $j.interiorColor) { buildString (' background-color: {0};' -f $j.interiorColor); }

        if ($null -ne $j.Halignment) {
            if ($null -ne $j.value) {
                $h = @(Switch ($j.value.GetType().Name) { 'int32' {'right'} 'decimal' {'right'} 'string' {'left'} default {'left'} });
            }
            buildString ('text-align: {0};' -f @(Switch ($j.Halignment) { '1' {$h} '-4108' {'center'} '-4131' {'left'} '-4152' {'right'} default {'left'} }));
        }
        if ($null -ne $j.Valignment) { buildString ('vertical-align: {0};' -f @(Switch ($j.Valignment) { '-4107' {'bottom'} '-4108' {'middle'} '-4160' {'text-top'} default {'middle'} })); }
        if ($null -ne $j.borderTopLineStyle) {
            buildString ('border-top-style: {0};' -f @(Switch ($j.borderTopLineStyle) { '1' {'solid'} '-4118' {'dotted'} '-4115' {'dashed'} default {'solid'} }));
            buildString ('border-top-width: {0};' -f @(Switch ($j.borderTopWeight) { '1' {'1px'} '2' {'2px'} '-4138' {'3px'} '4' {'4px'} default {'1px'} }));
            buildString ('border-top-color: {0};' -f $j.borderTopColor);
        }
        if ($null -ne $j.borderBottomLineStyle) {
            buildString ('border-bottom-style: {0};' -f @(Switch ($j.borderBottomLineStyle) { '1' {'solid'} '-4118' {'dotted'} '-4115' {'dashed'} default {'solid'} }));
            buildString ('border-bottom-width: {0};' -f @(Switch ($j.borderBottomWeight) { '1' {'1px'} '2' {'2px'} '-4138' {'3px'} '4' {'4px'} default {'1px'} }));
            buildString ('border-bottom-color: {0};' -f $j.borderBottomColor);
        }
        if ($null -ne $j.borderLeftLineStyle) {
            buildString ('border-left-style: {0};' -f @(Switch ($j.borderLeftLineStyle) { '1' {'solid'} '-4118' {'dotted'} '-4115' {'dashed'} default {'solid'} }));
            buildString ('border-left-width: {0};' -f @(Switch ($j.borderLeftWeight) { '1' {'1px'} '2' {'2px'} '-4138' {'3px'} '4' {'4px'} default {'1px'} }));
            buildString ('border-left-color: {0};' -f $j.borderLeftColor);
        }
        if ($null -ne $j.borderRightLineStyle) {
            buildString ('border-right-style: {0};' -f @(Switch ($j.borderRightLineStyle) { '1' {'solid'} '-4118' {'dotted'} '-4115' {'dashed'} default {'solid'} }));
            buildString ('border-right-width: {0};' -f @(Switch ($j.borderRightWeight) { '1' {'1px'} '2' {'2px'} '-4138' {'3px'} '4' {'4px'} default {'1px'} }));
            buildString ('border-right-color: {0};' -f $j.borderRightColor);
        }

        # end cell styling
        buildString '">';

        # add content
        if ($null -ne $j.type) {
            if ($j.type -eq 'date') { buildString ('<input id={0} name={0} type="{1}" placeholder="mm/dd/yyyy" style="background-color:inherit; ">' -f ($j.id, $j.type)); }
            if ($j.type -eq 'text') { buildString ('<input id={0} name={0} type="{1}" size=5 style="background-color:inherit;">' -f ($j.id, $j.type)); }
            if ($j.type -eq 'textarea') { buildString ('<textarea id={0} name={0} style="background-color:inherit;"></textarea>' -f ($j.id)); }
        }
        if ($null -ne $j.formula) {
            if ($preview) {
                buildString ('<input readonly id={0} name={0} placeholder={1} type=text style="font-family:inherit; background-color:inherit;" class="formula" formula=''{1}''>' -f ($j.id, $j.formula));
            } else {
                buildString ('<input readonly id={0} name={0} type=text style="font-family:inherit; background-color:inherit;" class="formula" formula=''{1}''>' -f ($j.id, $j.formula));
            }
        }
        if ($null -ne $j.validation) {
            buildString ('<select id={0} name={0} style="font-family:inherit; background-color:inherit;">' -f $j.id, $j.fontName);
            buildString "`n";
            $j.validation.GetEnumerator() | ForEach-Object {
                buildString ('<option value="{0}">{1}</option>' -f $_, $_);
                buildString "`n";
            }
            buildString '</select>';
            buildString "`n";
        }

        if ($null -ne $j.value) {
            if ($j.value.GetType().Name -eq 'int' -or $j.value.GetType().Name -eq 'decimal') {
                Switch ($j.format) {
                    'General' { buildString ('{0:g}' -f $j.value); }
                    '0.00' { buildString ('{0:n}' -f $j.value); }
                    '$#,##0.00_);[Red]($#,##0.00)' { buildString ('{0:c}' -f $j.value); }
                    default  { buildString ('{0:g}' -f $j.value); }
                }
            } else {
                buildString ('{0}' -f $j.value);
            }
        }
        # end cell
        buildString '</td>';

        # add to the array
        $table[$j.row, $j.col] = $sb.ToString();
    }
}

$sb.Clear();
buildString '<table>';
for ($r = 0; $r -lt $hArr.Length; $r++) {
    buildString '<tr>';
    for ($c = 0; $c -lt $wArr.Length; $c++) {
        buildString($table[$r, $c]);
        buildString "`n";
    }
    buildString '</tr>';
    buildString "`n";
}
buildString '</table>';


$html = $sb.ToString();
Write-Host $html;

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

