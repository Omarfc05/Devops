import { useState, useEffect } from "react";
import { Modal } from "./Modal";
import { FormDespacho } from "./FormDespacho";
import axios from "axios";

export const TableCompras = () => {
  const [ventas, setVentas] = useState([]);

  const compras = async () => {
    // CORRECCIÓN VITAL: Apuntando a tu entorno local (Asegúrate de que el microservicio de Ventas esté corriendo en este puerto)
    await axios.get("http://localhost:8080/api/v1/ventas", {
      headers:{
        'Content-Type': 'application/json',
        'Accept': 'application/json'
      }
    }).then((response) => {
      console.log(response.data);
      setVentas(response.data);
    }).catch((error) => {
      console.error("Error de conexión con Ventas:", error);
    });
  };

  useEffect(() => {
    compras();
  }, []);

  const [openModal, setOpenModal] = useState(false);
  const [ventaSeleccionada, setVentaSeleccionada] = useState(null);

  const handleAbrirModal = (venta) => {
    setVentaSeleccionada(venta);
    setOpenModal(true);
  };

  return (
      <>
        <section className="grid text-center grid-cols-12 mb-8 drop-shadow-xl font-sans">
          <div className="col-span-12 flex justify-center">

            {/* Contenedor principal: Efecto vidrio (Glassmorphism) con borde blanco iluminado */}
            <div className="col-span-10 p-4 bg-white/40 backdrop-blur-lg border border-white/70 rounded-3xl shadow-[0_8px_32px_rgba(0,180,255,0.2)] overflow-hidden">
              <table className="w-full table-fixed border-collapse">
                <thead>
                {/* Cabecera: Gradiente celeste agua optimista */}
                <tr className="bg-gradient-to-r from-sky-400 to-cyan-400 text-white shadow-sm">
                  <th className="py-5 font-semibold tracking-wide rounded-tl-2xl">Orden de compra</th>
                  <th className="py-5 font-semibold tracking-wide">Dirección</th>
                  <th className="py-5 font-semibold tracking-wide">Fecha de compra</th>
                  <th className="py-5 font-semibold tracking-wide">Valor total</th>
                  <th className="py-5 font-semibold tracking-wide rounded-tr-2xl">Acción</th>
                </tr>
                </thead>
                <tbody className="bg-white/50 divide-y divide-sky-100 text-slate-700">
                {ventas
                    .filter((venta) => !venta.despachoGenerado)
                    .map((venta) => (
                        <tr key={venta.idVenta} className="hover:bg-white/80 transition-colors duration-300">
                          <td className="py-6 items-center font-medium">{venta.idVenta}</td>
                          <td className="py-6 items-center">{venta.direccionCompra}</td>
                          <td className="py-6 items-center">{venta.fechaCompra}</td>
                          <td className="py-6 items-center font-bold text-sky-600">${venta.valorCompra}</td>
                          <td>
                            {/* Botón de acción: Efecto glossy tridimensional verde lima */}
                            <button
                                onClick={() => handleAbrirModal(venta)}
                                className="py-2 px-6 bg-gradient-to-b from-lime-300 to-green-500 hover:from-lime-200 hover:to-green-400 text-white font-bold rounded-full border border-white/80 shadow-[0_4px_15px_rgba(74,222,128,0.5)] transition-all duration-300 transform hover:scale-105 active:scale-95"
                            >
                              Generar Despacho
                            </button>
                          </td>
                        </tr>
                    ))}
                </tbody>
              </table>
            </div>

          </div>
        </section>

        <Modal
            onClose={() => {
              setOpenModal(false);
            }}
            open={openModal}
        >
          {ventaSeleccionada && (
              <FormDespacho
                  venta={ventaSeleccionada}
                  onClose={() => {
                    setOpenModal(false);
                    compras();
                  }}
              />
          )}
        </Modal>
      </>
  );
};