import { useState, useEffect } from "react";
import axios from "axios"

const API_VENTAS = "http://34.200.152.235/api/v1/ventas";
const API_DESPACHOS = "http://34.200.152.235/api/v1/despachos";

const Dashboard = () => {
    const [ventas, setVentas] = useState([]);
    const [despachos, setDespachos] = useState([]);

    // Estados para el formulario de nueva venta
    const [direccion, setDireccion] = useState("");
    const [valor, setValor] = useState("");

    const cargarDatos = async () => {
        try {
            const resVentas = await axios.get(API_VENTAS);
            setVentas(resVentas.data);
            const resDespachos = await axios.get(API_DESPACHOS);
            setDespachos(resDespachos.data);
        } catch (error) {
            console.error("Error cargando datos...:", error);
        }
    };

    useEffect(() => {
        cargarDatos();
    }, []);

    // FILTRO A PRUEBA DE BALAS:
    // Solo muestra las ventas que NO tengan despacho generado Y que NO existan ya en la tabla de despachos
    const ventasPendientes = ventas.filter(v =>
        !v.despachoGenerado && !despachos.some(d => d.idCompra === v.idVenta)
    );

    // Función CRUD: Crear Venta
    const registrarVenta = async (e) => {
        e.preventDefault();
        try {
            await axios.post(API_VENTAS, {
                direccionCompra: direccion,
                fechaCompra: new Date().toISOString().split('T')[0],
                valorCompra: parseInt(valor),
                despachoGenerado: false
            });
            setDireccion("");
            setValor("");
            cargarDatos(); // Recargar tablas automáticamente
        } catch (error) {
            console.error("Error al registrar venta:", error);
        }
    };

    // Función CRUD: Procesar Despacho
    const despacharVenta = async (venta) => {
        try {
            // Pasamos los datos que faltan desde el objeto 'venta' original
            await axios.post(API_DESPACHOS, {
                idCompra: venta.idVenta,
                fechaDespacho: new Date().toISOString().split('T')[0],
                patenteCamion: "B9-SALF",
                entregado: false,
                // Agregamos estos campos para que el backend los reciba y guarde
                direccionCompra: venta.direccionCompra,
                valorCompra: venta.valorCompra
            });

            await axios.put(`API_VENTAS/${venta.idVenta}`, {
                ...venta,
                despachoGenerado: true
            });

            cargarDatos();
        } catch (error) {
            console.error("Error al despachar:", error);
        }
    };

    return (
        <div className="max-w-6xl mx-auto space-y-8">
            {/* Cabecera Principal */}
            <div className="bg-white/50 backdrop-blur-xl border border-white/80 p-6 rounded-3xl shadow-[0_10px_40px_rgba(0,150,255,0.15)] flex justify-between items-center">
                <h1 className="text-4xl font-extrabold text-transparent bg-clip-text bg-gradient-to-r from-sky-500 to-blue-600 drop-shadow-sm">
                    📦 Central de Logística
                </h1>
                <button onClick={cargarDatos} className="bg-gradient-to-b from-white to-sky-50 text-sky-600 font-bold py-2 px-6 rounded-full border border-sky-200 shadow-md hover:shadow-lg transition-all active:scale-95">
                    ↻ Refrescar
                </button>
            </div>

            <div className="grid grid-cols-1 lg:grid-cols-3 gap-8">

                {/* Columna Izquierda: Formulario (Crear) */}
                <div className="bg-white/60 backdrop-blur-md border border-white p-6 rounded-3xl shadow-xl h-fit">
                    <h2 className="text-xl font-bold text-sky-800 mb-6 border-b border-sky-200 pb-2">Registrar Nueva Venta</h2>
                    <form onSubmit={registrarVenta} className="space-y-4">
                        <div>
                            <label className="block text-sm font-bold text-sky-700 mb-1">Dirección de Entrega</label>
                            <input
                                type="text" required value={direccion} onChange={(e) => setDireccion(e.target.value)}
                                className="w-full px-4 py-3 rounded-2xl bg-white/80 border border-white shadow-inner text-sky-900 focus:outline-none focus:ring-4 focus:ring-sky-300/40 transition-all"
                                placeholder="Ej. Gran Avenida 9000"
                            />
                        </div>
                        <div>
                            <label className="block text-sm font-bold text-sky-700 mb-1">Valor Total ($)</label>
                            <input
                                type="number" required value={valor} onChange={(e) => setValor(e.target.value)}
                                className="w-full px-4 py-3 rounded-2xl bg-white/80 border border-white shadow-inner text-sky-900 focus:outline-none focus:ring-4 focus:ring-sky-300/40 transition-all"
                                placeholder="45000"
                            />
                        </div>
                        <button type="submit" className="w-full mt-4 py-3 bg-gradient-to-b from-sky-400 to-blue-500 hover:from-sky-300 hover:to-blue-400 text-white font-bold rounded-2xl shadow-[0_8px_15px_rgba(0,150,255,0.3)] transform hover:-translate-y-1 transition-all">
                            + Agregar a Pendientes
                        </button>
                    </form>
                </div>

                {/* Columna Central: Ventas (Leer y Actualizar) */}
                <div className="bg-white/60 backdrop-blur-md border border-white p-6 rounded-3xl shadow-xl">
                    <h2 className="text-xl font-bold text-sky-800 mb-6 border-b border-sky-200 pb-2 flex items-center gap-2">
                        <span className="w-3 h-3 rounded-full bg-lime-400 shadow-[0_0_10px_rgba(163,230,53,0.8)]"></span>
                        Por Despachar
                    </h2>
                    <div className="space-y-4 max-h-[500px] overflow-y-auto pr-2">
                        {ventasPendientes.length === 0 ? <p className="text-sky-600/70 italic text-center py-4">Sin ventas pendientes</p> : null}
                        {ventasPendientes.map((v) => (
                            <div key={v.idVenta} className="bg-white/80 p-4 rounded-2xl border border-white shadow-sm flex flex-col gap-3">
                                <div>
                                    <p className="font-bold text-slate-700">Orden #{v.idVenta} <span className="text-sky-500 float-right">${v.valorCompra}</span></p>
                                    <p className="text-sm text-slate-500 mt-1">📍 {v.direccionCompra}</p>
                                </div>
                                <button
                                    onClick={() => despacharVenta(v)}
                                    className="py-2 bg-gradient-to-b from-lime-300 to-green-500 hover:from-lime-200 hover:to-green-400 text-white font-bold rounded-xl shadow-[0_4px_10px_rgba(74,222,128,0.4)] active:scale-95 transition-all"
                                >
                                    Confirmar Despacho
                                </button>
                            </div>
                        ))}
                    </div>
                </div>

                {/* Columna Derecha: Despachos (Leer) */}
                <div className="bg-white/60 backdrop-blur-md border border-white p-6 rounded-3xl shadow-xl">
                    <h2 className="text-xl font-bold text-sky-800 mb-6 border-b border-sky-200 pb-2 flex items-center gap-2">
                        <span className="w-3 h-3 rounded-full bg-blue-400 shadow-[0_0_10px_rgba(96,165,250,0.8)]"></span>
                        En Ruta
                    </h2>
                    <div className="space-y-4 max-h-[500px] overflow-y-auto pr-2">
                        {despachos.length === 0 ? <p className="text-sky-600/70 italic text-center py-4">No hay camiones en ruta</p> : null}
                        {despachos.map((d) => (
                            <div key={d.id} className="bg-gradient-to-br from-sky-50 to-white p-4 rounded-2xl border border-sky-100 shadow-sm relative overflow-hidden">
                                <div className="absolute top-0 right-0 bg-sky-200 text-sky-700 text-xs font-bold px-3 py-1 rounded-bl-xl">Activo</div>
                                <p className="font-bold text-sky-900 mt-2">🚚 {d.patenteCamion}</p>
                                <p className="text-sm text-sky-700 mt-1">Orden asociada: #{d.idCompra}</p>
                                <p className="text-xs text-sky-500 mt-2 font-medium">Fecha: {d.fechaDespacho}</p>
                            </div>
                        ))}
                    </div>
                </div>

            </div>
        </div>
    );
};

export default Dashboard;