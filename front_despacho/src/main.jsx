import React from 'react';
import ReactDOM from 'react-dom/client';
import Dashboard from './componentes/Dashboard';
import './index.css';

ReactDOM.createRoot(document.getElementById('root')).render(
    <React.StrictMode>
        <div className="min-h-screen bg-gradient-to-b from-sky-200 via-cyan-100 to-white p-8 font-sans bg-[url('https://www.transparenttextures.com/patterns/cubes.png')]">
            <Dashboard />
        </div>
    </React.StrictMode>,
);