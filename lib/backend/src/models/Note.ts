import mongoose, { Schema, Document } from 'mongoose';

export interface INote extends Document {
    title: string;
    content: any;
    date: Date;
    tags: string[];
    user: mongoose.Types.ObjectId;
    createdAt: Date;
    updatedAt: Date;
}

const NoteSchema: Schema = new Schema({
    title: { type: String, required: true },
    content: { type: Schema.Types.Mixed, required: true },
    date: { type: Date, default: Date.now },
    tags: [{ type: String }],
    user: { type: mongoose.Schema.Types.ObjectId, ref: 'User', required: true }
}, {
    timestamps: true
});

export default mongoose.model<INote>('Note', NoteSchema); 