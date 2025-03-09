import mammoth from 'mammoth';
import OpenAI from 'openai';
import { NextApiRequest, NextApiResponse } from 'next';
import JSZip from 'jszip';
import { Buffer } from 'buffer';
import fs from 'fs';
import { Formidable } from 'formidable'; // Corrected import

export const config = {
    api: {
        bodyParser: false, // Disable Next.js body parser for file handling
    },
};

interface Message {
    role: 'system' | 'user' | 'assistant';  // Possible roles
    content: string;
    name?: string;  // Optional, since name might not always be required
}

const openai = new OpenAI({ apiKey: process.env.NEXT_PUBLIC_OPEN_AI });

const CHUNK_SIZE = 3000; // Define your chunk size (e.g., 3000 characters)

export default async function handler(req: NextApiRequest, res: NextApiResponse) {
    if (req.method !== 'POST') {
        return res.status(405).json({ message: 'Method not allowed' });
    }

    try {
        const form = new Formidable(); // Corrected usage of Formidable
        form.parse(req, async (err, fields, files) => {
            if (err) {
                return res.status(400).json({ message: 'File upload error' });
            }

            // Ensure the file exists and get the correct path
            const uploadedFile = Array.isArray(files.file) ? files.file[0] : files.file;
            if (!uploadedFile) {
                return res.status(400).json({ message: 'No file provided' });
            }

            const filePath = uploadedFile.filepath || uploadedFile.filepath; // Some versions use `path`
            const fileBuffer = await fs.promises.readFile(filePath);

            // Extract text from the Word document
            let { value: text } = await mammoth.extractRawText({ buffer: fileBuffer });
            text = text.substring(0, 10000); // Reduce text size for API limits, if needed

            // Split the text into chunks based on your chunk size
            const chunks = [];
            for (let i = 0; i < text.length; i += CHUNK_SIZE) {
                chunks.push(text.substring(i, i + CHUNK_SIZE));
            }

            // Extract images from Word document
            const zip = await JSZip.loadAsync(fileBuffer);
            const imageFiles = Object.keys(zip.files).filter((file) =>
                file.startsWith('word/media/') && (file.endsWith('.png') || file.endsWith('.jpg') || file.endsWith('.jpeg'))
            );

            let imagesBase64 = [];
            for (const imageFile of imageFiles.slice(0, 3)) { // Limit to 3 images
                const imageBuffer = await zip.files[imageFile].async('nodebuffer');
                const base64String = imageBuffer.toString('base64');
                imagesBase64.push(`data:image/jpeg;base64,${base64String}`);
            }

            // Construct OpenAI request
            const messages: Message[] = [{ role: 'system', content: 'You are an assistant', name: 'system-assistant' }];

            // Prompt OpenAI para analizar el texto
            const prompt = `Analyze the word document, it contains texts that we want to separate into components:
                            """
                            ${text}
                            """
                            Return the response in JSON format with keys masthead, and rich text. The masthead must have a Title and a Description, and the Rich Text could be various paragraphs. Return only a JSON string`;

            messages.push({ role: 'user', content: prompt, name: 'user-question' });

            // Add chunks one by one to the messages
            let chunkCounter = 1;
            for (const chunk of chunks) {
                messages.push({
                    role: 'user',
                    content: chunk,  // Add one chunk at a time
                    name: `text-chunk-${chunkCounter}`
                });
                chunkCounter++;
            }

            // Call OpenAI API for each chunk separately if needed
            let allResponses: string[] = [];
            try {
                const openaiResponse = await openai.chat.completions.create({
                    model: 'chatgpt-4o-latest',
                    messages: messages,  // Send one message at a time (chunk or image)
                    max_tokens: 4000,
                    temperature: 0.5,
                });

                const responseContent = openaiResponse.choices?.[0]?.message?.content?.trim();
                if (responseContent) {
                    let cleanedResponse = responseContent;



                    allResponses.push(cleanedResponse);
                }
            } catch (error) {
                console.error('Error with OpenAI API:', error);
                // Handle errors gracefully
            }

            // Combine all responses into one
            const finalResponse = allResponses.join('\n');

            // Remove the surrounding code block (````json`` and closing ```)
            let jsonString = finalResponse.replace(/^\`\`\`json\n|\n\`\`\`$/, '').trim();
            jsonString = jsonString.replace(/```$/, '').trim();


            // Parse the cleaned JSON string
            let jsonObject = JSON.parse(jsonString);
            jsonObject.images = imagesBase64;


            res.status(200).json({ content: JSON.stringify(jsonObject) });

        });
    } catch (error) {
        console.error('Error processing request:', error);
        res.status(500).json({ message: 'Internal server error' });
    }
}
