param (
    [string] $jsonfile,
    [string] $htmlfile
)

[Reflection.Assembly]::LoadFile("u://json2html/measurestring.dll");

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

foreach ($j in $jobj) {
    $h = $j | ConvertTo-Hashtable

    if ($null -ne $h['normalfont']) {
        $normalfont = $h['normalfont'];
        $normalsize = $h['normalsize'];
        $wunit = [int]([measurestring]::fontWidth($normalfont, $normalsize, "00") / 2);
    }
    if ($null -ne $h['x']) {
        if ($null -ne $h['value'] -or $null -ne $h['type']) {
            $html += '<div style="position: fixed; left:{0}px; top: {1}px; font-size: {2}px; font-family: {3};' -f [int]($h['x'] * $wunit), $h['y'], $h['fontSize'], $h['fontName'];

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
                    $html += '"><textarea id={0} name={0} rows={1} cols={2} style="font-family:inherit;"></textarea></div>' -f ($h['id'], ($h['height'] / ($normalsize * 1.5)), $h['width']);
                } else {
                    $size = [int]($h['width'] * $wunit);
                    $html += '"><input id={0} name={0} type="{1}" style="width: {2}px; font-family:inherit;"></div>' -f ($h['id'], $h['type'], $size);
                }
            } else {
                $html += '">{0}</div>' -f $h['value'];
            }

            $html += "`n";
        }
        if ($null -ne $h['validation']) {
            $html += '<div style="position: fixed; left:{0}px; top: {1}px; font-size: {2}px; font-family: {3};' -f [int]($h['x'] * $wunit), $h['y'], $h['fontSize'], $h['fontName'];
            $html += '"><select id={0} name={0} style="width: {1}px;">' -f $h['id'], [int]($h['width'] * $wunit);
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
    }
}

((Get-Content './form.html') -replace 'formhtmld8ee24e6-747a-4bda-93f0-090d7ee7d675', $html) | Set-Content $htmlfile;

