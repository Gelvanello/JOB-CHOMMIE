import React from 'react';
import { Canvas } from '@react-three/fiber';
import { OrbitControls, Stars, Float } from '@react-three/drei';

function Cube() {
  return (
    <Float>
      <mesh rotation={[45, 45, 0]}>
        <boxGeometry args={[1, 1, 1]} />
        <meshStandardMaterial color="hotpink" />
      </mesh>
    </Float>
  );
}

export default function ThreeHero() {
  return (
    <div className="w-full h-64 md:h-96">
      <Canvas camera={{ position: [3, 3, 3] }}>
        <ambientLight intensity={0.5} />
        <pointLight position={[10, 10, 10]} />
        <Stars />
        <Cube />
        <OrbitControls enableZoom={false} />
      </Canvas>
    </div>
  );
}
