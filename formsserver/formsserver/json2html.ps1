param (
    [string] $jsonfile,
    [string] $htmlfile,
    [string] $ip,
    [string] $usr
)

#$jsonfile = '\\file01\data\nmmc documents\Scripts\excelToJson\test.prev';
#$htmlfile = 'test.html';
#$ip = '10.1.2.63';
#$usr = 'swarner';

[Reflection.Assembly]::LoadFile("C:\scripts\nodejs\formsserver\measurestring.dll") | Out-Null;

$json = Get-Content $jsonfile;
$jobj = ($json | ConvertFrom-Json);

Write-Host 'Start' -NoNewline;
foreach ($j in $jobj) {
    Write-Host '.' -NoNewline;
    if ($null -ne $j.normalfont) {
        $normalfont = $j.normalfont;
        $normalsize = $j.normalsize;
        $wunit = [int]([measurestring]::fontWidth($normalfont, $normalsize, "0") * .75);
        $title = $j.title;
        $description = $j.description;
        $approval = $j.approval;
        $preview = $j.preview;
        [int32[]]$wArr = $j.wArr;
        [int32[]]$hArr = $j.hArr;

        $table = New-Object 'object[,]' ($hArr.length + 1), ($wArr.length + 1);

        if ($preview) {
            $borderEdge = '1px solid gray';
            $table[0,0] = '<td width=5 height=5 style=" color: #A9A9A9; background-color: #e5e4e2;">&#x25e2</td>';
            
            # table row 0 defines column widths
            for ($c=0; $c -lt $wArr.length; $c++) {
                $label = $(Switch($c + 65) { {$_ -in 65..90 } { [char]($_); }  {$_ -in 91..117 } { 'A' + [char]($_ - 26); } default { $_; }});
                $table[0, ($c + 1)] = '<td width={0} style="text-align: center; background-color: #e5e4e2; border-left:{2}; border-bottom:{2};">{1}</td>' -f ($wArr[$c] * $wunit), $label, $borderEdge;
            }
            # table column 0 defines row heights
            for ($r=0; $r -lt $hArr.length; $r++) {
                $table[($r + 1), 0] = '<td height={0} style=" background-color: #e5e4e2; border-top:{2}; border-right:{2};">{1}</td>' -f $hArr[$r], ($r + 1), $borderEdge;
            }
        } else {
            $table[0,0] = '<td width=5 height=5 style=" color: #A9A9A9; background-color: #ffffff;"></td>';

            # table row 0 defines column widths
            for ($c=0; $c -lt $wArr.length; $c++) {
                $table[0, ($c + 1)] = '<td width={0} style="text-align: center; background-color: #ffffff;"></td>' -f ($wArr[$c] * $wunit);
            }
            # table column 0 defines row heights
            for ($r=0; $r -lt $hArr.length; $r++) {
                $table[($r + 1), 0] = '<td height={0} style=" white-space: nowrap; background-color: #ffffff;"></td>' -f $hArr[$r];
            }
        }
    } else {
        $table[$j.row, $j.col] = [System.Text.StringBuilder]::new();

        if ($preview) {
            [void]$table[$j.row, $j.col].Append('<td class="preview" ');
        } else {
            [void]$table[$j.row, $j.col].Append('<td ');
        }
        
        # add spans & style
        if ($null -ne $j.colspan) {
            if ($j.rowspan -gt 1) {
                $td_height = $($hArr[$j.row..($j.row + $j.rowspan - 1)] | Measure-Object -Sum).Sum;
            } else {
                $td_height = $hArr[$j.row];
            }
            if ($j.colspan -gt 1) {
                $td_width = $($wArr[$j.col..($j.col + $j.colspan - 1)] | Measure-Object -Sum).Sum;
            } else {
                $td_width = $wArr[$j.col];
            }
            [void]$table[$j.row, $j.col].Append(('colspan={0} rowspan={1} width={2} height={3} style="' -f $j.colspan, $j.rowspan, $td_width, $td_height));
        } else {
            [void]$table[$j.row, $j.col].Append(('height={0} style="' -f $hArr[$j.row]));
        }

        # add cell styling
        if ($null -ne $j.fontName) { [void]$table[$j.row, $j.col].Append(' font-family: {0};' -f $j.fontName); }
        if ($null -ne $j.fontSize) { [void]$table[$j.row, $j.col].Append(' font-size: {0}px;' -f $j.fontSize); }
        if ($null -ne $j.fontBold) { [void]$table[$j.row, $j.col].Append(' font-weight: bold;'); }
        if ($null -ne $j.fontItalic) { [void]$table[$j.row, $j.col].Append(' font-style: italic;'); }
        if ($null -ne $j.fontColor) { [void]$table[$j.row, $j.col].Append(' color: {0};' -f $j.fontColor); }
        if ($null -ne $j.interiorColor) { [void]$table[$j.row, $j.col].Append(' background-color: {0};' -f $j.interiorColor); }

        if ($null -ne $j.Halignment) {
            if ($null -ne $j.value) {
                $h = @(Switch ($j.value.GetType().Name) { 'int32' {'right'} 'decimal' {'right'} 'string' {'left'} default {'left'} });
            }
            [void]$table[$j.row, $j.col].Append('text-align: {0};' -f @(Switch ($j.Halignment) { '1' {$h} '-4108' {'center'} '-4131' {'left'} '-4152' {'right'} default {'left'} }));
        }
        if ($null -ne $j.Valignment) { [void]$table[$j.row, $j.col].Append('vertical-align: {0};' -f @(Switch ($j.Valignment) { '-4107' {'bottom'} '-4108' {'middle'} '-4160' {'text-top'} default {'middle'} })); }
        if ($null -ne $j.borderTopLineStyle) {
            [void]$table[$j.row, $j.col].Append('border-top: {0} {1} {2};' -f (`
                $(Switch ($j.borderTopWeight) { '1' {'1px'} '2' {'2px'} '-4138' {'3px'} '4' {'4px'} default {'1px'} }),`
                $(Switch ($j.borderTopLineStyle) { '1' {'solid'} '-4118' {'dotted'} '-4115' {'dashed'} default {'solid'} }), `
                $j.borderTopColor));
        }
        if ($null -ne $j.borderBottomLineStyle) {
            [void]$table[$j.row, $j.col].Append('border-bottom: {0} {1} {2};' -f (`
                $(Switch ($j.borderBottomWeight) { '1' {'1px'} '2' {'2px'} '-4138' {'3px'} '4' {'4px'} default {'1px'} }),`
                $(Switch ($j.borderBottomLineStyle) { '1' {'solid'} '-4118' {'dotted'} '-4115' {'dashed'} default {'solid'} }), `
                $j.borderBottomColor));
        }
        if ($null -ne $j.borderLeftLineStyle) {
            [void]$table[$j.row, $j.col].Append('border-left: {0} {1} {2};' -f (`
                $(Switch ($j.borderLeftWeight) { '1' {'1px'} '2' {'2px'} '-4138' {'3px'} '4' {'4px'} default {'1px'} }),`
                $(Switch ($j.borderLeftLineStyle) { '1' {'solid'} '-4118' {'dotted'} '-4115' {'dashed'} default {'solid'} }), `
                $j.borderLeftColor));
        }
        if ($null -ne $j.borderRightLineStyle) {
            [void]$table[$j.row, $j.col].Append('border-right: {0} {1} {2};' -f (`
                $(Switch ($j.borderRightWeight) { '1' {'1px'} '2' {'2px'} '-4138' {'3px'} '4' {'4px'} default {'1px'} }),`
                $(Switch ($j.borderRightLineStyle) { '1' {'solid'} '-4118' {'dotted'} '-4115' {'dashed'} default {'solid'} }), `
                $j.borderRightColor));
        }

        # end cell styling
        [void]$table[$j.row, $j.col].Append('">');

        # define value
        $value = '';
        if ($null -ne $j.value) {
            if ($j.value.GetType().Name -eq 'int' -or $j.value.GetType().Name -eq 'decimal') {
                Switch ($j.format) {
                    'General' { $value = '{0:g}' -f $j.value; }
                    '0.00' { $value = '{0:n}' -f $j.value; }
                    '$#,##0.00_);[Red]($#,##0.00)' { $value = '{0:c}' -f $j.value; }
                    default  { $value = '{0:g}' -f $j.value; }
                }
            } else {
                $value = '{0}' -f $j.value;
            }
        }
        # add content
        if ($null -ne $j.type) {
            if ($j.type -eq 'date') { [void]$table[$j.row, $j.col].Append('<input id={0} name={0} type="{1}" placeholder="mm/dd/yyyy" value="{2}" style="background-color:inherit; ">' -f ($j.id, $j.type, $value)); }
            if ($preview) {
                if ($j.type -eq 'text') { [void]$table[$j.row, $j.col].Append('<input id={0} name={0} type="search" placeholder="{2}" size=5 value="{3}" style="background-color:inherit;">' -f ($j.id, $j.type, $j.format, $value)); }
                if ($j.type -eq 'textreadonly') { [void]$table[$j.row, $j.col].Append('<input id={0} name={0} type="search" placeholder="{2}" size=5 value="{3}" readonly style="background-color:inherit;">' -f ($j.id, $j.type, $j.format, $value)); }
                if ($j.type -eq 'textarea') { [void]$table[$j.row, $j.col].Append('<textarea id={0} name={0} placeholder="{1}" style="background-color:inherit;"></textarea>' -f ($j.id, $j.format, $value)); }
            } else {
                if ($j.type -eq 'text') { [void]$table[$j.row, $j.col].Append('<input id={0} name={0} type="search" size=5 value="{3}" style="background-color:inherit;">' -f ($j.id, $j.type, $j.format, $value)); }
                if ($j.type -eq 'textreadonly') { [void]$table[$j.row, $j.col].Append('<input id={0} name={0} type="search" size=5 value="{3}" readonly style="background-color:inherit;">' -f ($j.id, $j.type, $j.format, $value)); }
                if ($j.type -eq 'textarea') { [void]$table[$j.row, $j.col].Append('<textarea id={0} name={0} style="background-color:inherit;"></textarea>' -f ($j.id, $j.format, $value)); }
            }
        }
        if ($null -ne $j.formula) {
            if ($preview) {
                [void]$table[$j.row, $j.col].Append('<input readonly id={0} name={0} placeholder={1} type=text style="font-family:inherit; background-color:inherit;" class="formula" formula=''{1}''>' -f ($j.id, $j.formula));
            } else {
                [void]$table[$j.row, $j.col].Append('<input readonly id={0} name={0} type=text style="font-family:inherit; background-color:inherit;" class="formula" formula=''{1}''>' -f ($j.id, $j.formula));
            }
        }
        if ($null -ne $j.validation) {
            [void]$table[$j.row, $j.col].Append(('<select id={0} name={0} style="font-family:inherit; background-color:inherit;">' -f $j.id, $j.fontName));
            #[void]$table[$j.row, $j.col].Append("`n");
            $j.validation.GetEnumerator() | ForEach-Object {
                [void]$table[$j.row, $j.col].Append(('<option value="{0}">{1}</option>' -f $_, $_));
                #[void]$table[$j.row, $j.col].Append("`n");
            }
            [void]$table[$j.row, $j.col].Append('</select>');
            #[void]$table[$j.row, $j.col].Append("`n");
        }
        if ($null -eq $j.type -and $null -eq $j.formula -and $null -eq $j.validation) { #for now this is OK
            [void]$table[$j.row, $j.col].Append($value);
        }
        # close cell
        [void]$table[$j.row, $j.col].Append('</td>');
    }
}
Write-Host "End";

$sb = [System.Text.StringBuilder]::new();
$table_width = 5 + $($wArr | Measure-Object -Sum).Sum; # note default width of column 1 = 5, wider with > 99 rows ................ NEEDS WORK

[void]$sb.Append('<table style="min-width:{0}px; max-width: 200%;">' -f ($wunit * $table_width)); # prevent table from resizing with browser
if ($preview) {
    [void]$sb.Append('<div class="watermark">Preview Mode</div>');
}
for ($r = 0; $r -lt $hArr.Length; $r++) {
    [void]$sb.Append('<tr>');
    for ($c = 0; $c -lt $wArr.Length; $c++) {
        if ($null -ne $table[$r, $c]) {
            [void]$sb.Append($($table[$r, $c]));
            #[void]$sb.Append("`n");
        }
    }
    [void]$sb.Append('</tr>');
    #[void]$sb.Append("`n");
}
[void]$sb.Append('</table>');

$html = $sb.ToString();
#Write-Host $html;

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

#Write-Host $Matches.ADuser;
#Write-Host $Matches.session;
#Write-Host $Matches.logontime;

$user = $Matches.ADuser;
$session = $Matches.session;
$logontime = $Matches.logontime;

# get most recent rdp connection time from the event log
if ($session -like '*rdp-tcp#*') {
    $ago = (Get-Date) - (New-TimeSpan -Day 2);
    $logname = 'Microsoft-Windows-TerminalServices-LocalSessionManager/Operational'; #25 - session reconnected
    $messages = Get-WinEvent -ComputerName $ip -LogName $logname | Where-Object { $_.TimeCreated -ge $ago -and $_.Id -eq 25};
    foreach ($_ in $messages) {
#        Write-Host $_.TimeCreated;
        $logontime = $_.TimeCreated;
        break;
    }
}

$aduser = Get-ADUser $Matches.ADuser -Properties * | Select-Object Name, EmailAddress;
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

