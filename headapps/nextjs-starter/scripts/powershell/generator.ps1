# Prompt user to select an item location from Sitecore structure
$dialog1 = Read-Variable -Parameters @{
    Name = "selectedItem"
    Title = "Select Location"
    Root = "$($siteNode.Paths.FullPath)/Data/POIs"
    Editor = "item"
} -Description "This module is used to import Data." `
    -Width 400 -Height 200 `
    -Title "Import Utility" `
    -OkButtonName "Import" `
    -CancelButtonName "Cancel"

# Output the selected item ID for debugging
Write-Host "Selected item ID: " $selectedItem.ID

# If no item is selected, exit
if (-not $selectedItem) {
    Write-Host "No item selected."
    exit
}

# Output the selected item name and extension for debugging
Write-Host "Selected item name: $($selectedItem.Name)"
Write-Host "Selected item extension: $($selectedItem.Extension)"

# Validate if the selected item has a .docx extension
if ($selectedItem.Extension -eq "docx") {
    Write-Host "The selected item is a valid Word document (.docx)."

    # Ensure the selected item is a media item (docx template)
    if ($selectedItem.TemplateName -eq "docx") {
        # Get the media item using the selected item ID
        $mediaItem = Get-Item -Path "master:/$($selectedItem.ID)"

        if ($mediaItem) {
            Write-Host "The selected item is a media item."

            # Cast the item to MediaItem
            $media = [Sitecore.Data.Items.MediaItem]$mediaItem

            if ($media) {
                # Get the media stream
                $stream = $media.GetMediaStream()

                # Convert stream to byte array
                $memoryStream = New-Object System.IO.MemoryStream
                $stream.CopyTo($memoryStream)
                $stream.Close()
                $fileBytes = $memoryStream.ToArray()

                # API URL
                $apiUrl = "http://host.docker.internal:3000/api/openai/generator"

                # Boundary para multipart/form-data
                $boundary = [System.Guid]::NewGuid().ToString()
                $LF = "`r`n"

                # Construir cuerpo de multipart/form-data correctamente
                $bodyStart = "--$boundary$LF" +
                             "Content-Disposition: form-data; name=`"file`"; filename=`"$($selectedItem.Name).docx`"$LF" +
                             "Content-Type: application/vnd.openxmlformats-officedocument.wordprocessingml.document$LF$LF"

                $bodyEnd = "$LF--$boundary--$LF"

                # Convertir partes del cuerpo en bytes
                $bodyStartBytes = [System.Text.Encoding]::UTF8.GetBytes($bodyStart)
                $bodyEndBytes = [System.Text.Encoding]::UTF8.GetBytes($bodyEnd)

                # Crear cuerpo final de la solicitud
                $fullBody = New-Object System.IO.MemoryStream
                $fullBody.Write($bodyStartBytes, 0, $bodyStartBytes.Length)
                $fullBody.Write($fileBytes, 0, $fileBytes.Length)
                $fullBody.Write($bodyEndBytes, 0, $bodyEndBytes.Length)
                $fullBodyBytes = $fullBody.ToArray()

                # Encabezados HTTP
                $headers = @{
                    "Content-Type" = "multipart/form-data; boundary=$boundary"
                }

                # Enviar el archivo a la API
                try {
                    $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $fullBodyBytes
                    Write-Host "Response from API: $response"
                } catch {
                    Write-Host "Error calling API: $_"
                }
            } else {
                Write-Host "Unable to retrieve media for the selected item."
            }
            
        } else {
            Write-Host "Selected item is not a valid media item."
        }
    } else {
        Write-Host "The selected item is not a docx file (template name is not 'docx')."
    }
} else {
    Write-Host "Selected item is not a valid Word document (expected .docx)."
}