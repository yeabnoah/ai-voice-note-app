import express, { Request, Response } from 'express';
import mongoose from 'mongoose';
import dotenv from 'dotenv';
import { auth } from './middleware/auth';
import * as authController from './controllers/authController';
import * as noteController from './controllers/noteController';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(express.json());

// Database connection
mongoose.connect(process.env.MONGODB_URI || 'mongodb://localhost:27017/notes-app')
    .then(() => console.log('Connected to MongoDB'))
    .catch(err => console.error('MongoDB connection error:', err));

app.get("/health", (req: Request, res: Response) => {
    try {
        res.status(200).json({
            message: "app is healthy",
            status: true
        });
    } catch (error) {
        console.error("Health check error:", error); 
        res.status(500).json({
            message: "something went wrong",
            status: false
        });
    }
});

// Auth routes
app.post('/auth/register', authController.register);
app.post('/auth/login', authController.login);
app.post('/signinwithgoogle', authController.googleSignIn);
app.get('/auth/me', auth, authController.getCurrentUser);

// Note routes (protected)
app.get('/note/getallnotes', auth, noteController.getAllNotes);
app.get('/note/singlenote/:id', auth, noteController.getSingleNote);
app.post('/note/createNote', auth, noteController.createNote);
app.put('/note/singlenote/:id', auth, noteController.updateNote);
app.delete('/note/singlenote/:id', auth, noteController.deleteNote);

app.listen(PORT, () => {
    console.log(`Server running on port ${PORT}`);
});