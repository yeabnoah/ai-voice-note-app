import dotenv from 'dotenv';
import { Request, Response } from "express";


dotenv.config();
const { GoogleGenerativeAI } = require("@google/generative-ai");

const genAI = new GoogleGenerativeAI(process.env.API_KEY_AI);
const model = genAI.getGenerativeModel({ model: "gemini-1.5-flash"});


const generateContent = async (req: Request, res: Response): Promise<void> => {
    try {
        const { note, theme } = req.body;

        if (!note || !theme) {
            res.status(400).json({ 
                message: "Both note and theme are required" 
            });
            return;
        }

        const prompt = `Rewrite the following note in a ${theme} style/tone while preserving the core message and meaning:

Note: ${note}

Please maintain the original information but adapt the writing style to match the ${theme} theme/vibe. Make it engaging and natural.`;

        const result = await model.generateContent(prompt);
        const response = await result.response;
        const text = response.text();
        
        res.json({
            original: note,
            theme: theme,
            rewritten: text
        });
    }
    catch(err) {
        console.error("AI Generation Error:", err);
        res.status(500).json({
            message: "Error generating content",
            error: err instanceof Error ? err.message : "Unexpected error"
        });
    }
}

export default generateContent;
