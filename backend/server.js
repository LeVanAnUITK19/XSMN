import express from 'express';
import dotenv from 'dotenv';
import cors from 'cors';
import {connectDB} from './src/config/db.js';
import resultRoutes from "./src/routes/result_route.js";

dotenv.config();
const app = express();

app.use(cors());
app.use(express.json());

await connectDB(process.env.MONGODB_CONNECTIONSTRING)
.then(() => console.log("DB connected"))
  .catch(err => console.error(err));

app.use("/api/results", resultRoutes);

const PORT = process.env.PORT || 5001;
app.listen(PORT, '0.0.0.0', () => {
    console.log(`Server is running on port ${PORT}`);
});