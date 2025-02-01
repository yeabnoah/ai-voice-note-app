import { Request, Response } from 'express';
import Note from '../models/Note';

export const getAllNotes = async (req: Request, res: Response) => {
    try {
        const notes = await Note.find({ user: req.user.userId });
        res.json(notes);
    } catch (error) {
        res.status(500).json({ message: 'Server error' });
    }
};

export const getSingleNote = async (req: Request, res: Response) => {
    try {
        const note = await Note.findOne({ _id: req.params.id, user: req.user.userId });
        if (!note) {
            res.status(404).json({ message: 'Note not found' });
        }
        res.json(note);
    } catch (error) {
        res.status(500).json({ message: 'Server error' });
    }
};

export const createNote = async (req: Request, res: Response) => {
    try {
        const { title, content, tags } = req.body;
        const note = new Note({
            title,
            content,
            tags,
            user: req.user.userId
        });
        await note.save();
        res.status(201).json(note);
    } catch (error) {
        res.status(500).json({ message: 'Server error' });
    }
};

export const updateNote = async (req: Request, res: Response) => {
    try {
        const { title, content, tags } = req.body;
        const note = await Note.findOneAndUpdate(
            { _id: req.params.id, user: req.user.userId },
            { title, content, tags },
            { new: true }
        );
        if (!note) {
            res.status(404).json({ message: 'Note not found' });
        }
        res.json(note);
    } catch (error) {
        res.status(500).json({ message: 'Server error' });
    }
};

export const deleteNote = async (req: Request, res: Response) => {
    try {
        const note = await Note.findOneAndDelete({ _id: req.params.id, user: req.user.userId });
        if (!note) {
            res.status(404).json({ message: 'Note not found' });
        }
        res.json({ message: 'Note deleted' });
    } catch (error) {
        res.status(500).json({ message: 'Server error' });
    }
}; 