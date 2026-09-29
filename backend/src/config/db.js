import mongoose from 'mongoose';

export const connectDB = async (connectionString) => {
    try {
        await mongoose.connect(process.env.MONGODB_CONNECTIONSTRING, {
            maxPoolSize: 50,              // tăng từ default 5 → 50 connections song song
            minPoolSize: 10,              // giữ sẵn 10 connections, tránh overhead tạo mới
            serverSelectionTimeoutMS: 5000,
            socketTimeoutMS: 45000,
        });
        console.log('Kết nối đến MongoDB thành công');
    } catch (error) {
        console.error('Lỗi kết nối đến MongoDB:', error);
        process.exit(1);
    }
};