import { motion } from 'framer-motion';
import Lottie from 'lottie-react';
import bannerAnimation from '../assets/banner-lottie.json';

export default function Banner() {
  return (
    <motion.div 
      initial={{ opacity: 0, y: -50 }} 
      animate={{ opacity: 1, y: 0 }} 
      transition={{ duration: 1.2 }}
      className="bg-gradient-to-r from-indigo-500 via-purple-500 to-pink-500 p-6 rounded-xl shadow-2xl mb-6 text-white text-center"
    >
      <h1 className="text-2xl md:text-4xl font-bold">AI Job Chommie – Find Your Dream Job, Powered by AI</h1>
      <p className="mt-2 text-sm md:text-base">Helping South Africans connect with better opportunities through smart tech.</p>
      <div className="w-40 mx-auto mt-4">
        <Lottie animationData={bannerAnimation} loop={true} />
      </div>
    </motion.div>
  );
}
