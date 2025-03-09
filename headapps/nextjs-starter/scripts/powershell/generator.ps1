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

                $response = {};

                # Enviar el archivo a la API
                try {
                    $response = Invoke-RestMethod -Uri $apiUrl -Method Post -Headers $headers -Body $fullBodyBytes
                    Write-Host "Response from API: $response"
                } catch {
                    Write-Host "Error calling API: $_"
                    exit
                }
                
                # Define the template path
                $generatedPage = "/sitecore/templates/Project/sites/Generated Page"
                $dataTemplate = "/sitecore/templates/Foundation/Experience Accelerator/Local Datasources/Page Data"
                $RTFbasicComponent = "/sitecore/templates/Project/nextjs-starter/Basic Components/Rich Text Basic Component"
                $ImageComponent = "/sitecore/templates/Project/nextjs-starter/Basic Components/Image Basic Component"
                
                $homeItem = "/sitecore/content/sites/nextjs-starter/Home"
                
                $data = $response.content | ConvertFrom-Json
                
                # Define the item name based on title
                $itemName = [Sitecore.Data.Items.ItemUtil]::ProposeValidItemName($data.masthead.title)
                
                # Create the item in Sitecore
                $parentItem = Get-Item -Path $homeItem
                if ($parentItem -ne $null) {
                    $newItem = New-Item -Path $parentItem.Paths.FullPath -Name $itemName -ItemType $generatedPage
                    if ($newItem -ne $null) {
                		$newItemData = New-Item -Path $newItem.Paths.FullPath -Name "Data" -ItemType $dataTemplate
                		
                		if ($newItemData -ne $null) {
                			
                			$newRtfBasicComponent = New-Item -Path $newItemData.Paths.FullPath -Name "New Rich Text Basic Component" -ItemType $RTFbasicComponent
                			$newImageComponent = New-Item -Path $newItemData.Paths.FullPath -Name "New Image Component" -ItemType $ImageComponent
                			
                			if (($newRtfBasicComponent -ne $null) -and ($newImageComponent -ne $null)) {
                				$newItem.Editing.BeginEdit()
                				$newItemData.Editing.BeginEdit()
                				$newRtfBasicComponent.Editing.BeginEdit()
                				$newItem["Masthead Title"] = $data.masthead.title
                				$newItem["Masthead Description"] = $data.masthead.description
                				$newRtfBasicComponent["Rich Text Field"] = $data.rich_text
                				#$newImageComponent["Image Field"] = $data.image
                				
                				$layoutField = "{96E5F4BA-A2CF-4A4C-A4E7-64DA88226362}"  # Standard Layout field ID
                				$layout = [Sitecore.Layouts.LayoutDefinition]::Parse($newItem[$layoutField])
                
                				$RTFrendering = New-Object Sitecore.Layouts.RenderingDefinition
                				$RTFrendering.ItemID = "{6282BB17-3DC5-4DA3-9E6D-780D472BB039}"
                				$RTFrendering.Datasource = $newRtfBasicComponent.Paths.FullPath
                				
                				$ImageRendering = New-Object Sitecore.Layouts.RenderingDefinition
                				$ImageRendering.ItemID = "{1572AD3F-9732-440E-92EB-031B44B3B850}"
                				$ImageRendering.Datasource = $newImageComponent.Paths.FullPath
                				
                				
                				# Parameters
                                $mediaLibraryPath = "/sitecore/media library/Images/MyNewImage"
                                $now = Get-Date
                                $imageName = "MyImage" + $now
                                $base64String = $data.images[0]  # Replace with actual Base64 string
                                $mediaExtension = "jpg"  # Change based on your image type (jpg, png, etc.)
                                $database = [Sitecore.Configuration.Factory]::GetDatabase("master")
                                
                                # Your base64 string with the "data:image/jpeg;base64," prefix
                                
                                # Remove the prefix ("data:image/jpeg;base64,") if it exists
                                $base64StringCleaned = $base64String -replace '^data:image\/jpeg;base64,', ''
                                
                                # Now convert the base64 string to bytes
                                $bytes = [Convert]::FromBase64String($base64StringCleaned)
                                
                                # Create a new Media Item
                                $mediaItem = New-Item -Path $mediaLibraryPath -ItemType "jpeg" -Name $imageName -Language "en"
                                
                                # Set the image content
                                $media = [Sitecore.Resources.Media.MediaManager]::GetMedia($mediaItem)
                                $stream = New-Object System.IO.MemoryStream(, $bytes)
                                $media.SetStream($stream, $mediaExtension)
                                $mediaItem.Editing.EndEdit()
                				
                

                				# Define the placeholder (this would be your content area, e.g., "main-content")
                                $placeholderKeyRTF = "/headless-main/sxa-generated-content/gs-rtf-1"
                                $placeholderKeyimage = "/headless-main/sxa-generated-content/gs-image-1"
                                
                                Add-Rendering -Item $newItem -PlaceHolder $placeholderKeyRTF -Instance $RTFrendering -Parameter @{ "Reset Caching Options" = "1" } -FinalLayout
                                Add-Rendering -Item $newItem -PlaceHolder $placeholderKeyimage -Instance $RTFrendering -Parameter @{ "Reset Caching Options" = "1" } -FinalLayout

                				
                				$newRtfBasicComponent.Editing.EndEdit()
                				$newItemData.Editing.EndEdit()
                				$newItem.Editing.EndEdit()
                				Write-Host "Item created successfully: $($newItem.Paths.FullPath)"
			}
		}
    }
	else {
        Write-Host "Failed to create item."
    }
}
else {
    Write-Host "Parent path not found."
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
