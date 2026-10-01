# =====================================================================
# Punto 8: generador de datos de prueba. Crea un CSV por tabla en datos/.
# Uso (desde la raíz del proyecto):  python datos/generar.py
# Opcional: python datos/generar.py <reservas_por_habitacion> <huespedes>
# Por defecto: 10.000 habitaciones x 600 = 6.000.000 de reservas.
# Las reservas de cada habitación se generan una detrás de otra, así que
# nunca se superponen y el trigger no hace falta durante la carga.
# =====================================================================
import csv, os, random, sys, datetime as dt

random.seed(2026)                       # mismos datos en las tres PC
OUT = os.path.dirname(os.path.abspath(__file__))
RES_POR_HAB = int(sys.argv[1]) if len(sys.argv) > 1 else 600
HUESPEDES   = int(sys.argv[2]) if len(sys.argv) > 2 else 1_000_000
HOTELES, HAB_POR_HOTEL = 200, 50
HOY, INICIO = dt.date(2026, 10, 1), dt.date(2018, 1, 1)
N = r'\N'                               # NULL para LOAD DATA

def escribir(nombre, filas):
    with open(os.path.join(OUT, nombre), 'w', newline='', encoding='utf-8') as f:
        csv.writer(f, lineterminator='\n').writerows(filas)
    print(f'{nombre} listo')

# Ubicación: 5 países, 50 provincias, 300 ciudades
escribir('paises.csv', [(1,'Argentina','AR'),(2,'Chile','CL'),(3,'Uruguay','UY'),(4,'Brasil','BR'),(5,'Paraguay','PY')])
escribir('provincias.csv', [(i, (i-1)//10 + 1, f'Provincia {i}') for i in range(1, 51)])
escribir('ciudades.csv',   [(i, (i-1)//6 + 1,  f'Ciudad {i}')    for i in range(1, 301)])

# Hoteles con 2 contactos cada uno
escribir('hoteles.csv', [(i, f'Hotel {i}', random.randint(1,5), random.randint(1,300), f'Calle {i} {random.randint(1,3000)}') for i in range(1, HOTELES+1)])
escribir('contactos_hotel.csv', [(h, t, v) for h in range(1, HOTELES+1)
                                 for t, v in (('telefono', f'+54 351 {400000+h}'), ('email', f'reservas{h}@hoteles.com'))])

# Puntos de interés: 6 categorías, 1.000 puntos, 5 cerca de cada hotel
cats = ['Museo','Playa','Restaurante','Parque','Estadio','Centro comercial']
escribir('categorias.csv', [(i+1, c) for i, c in enumerate(cats)])
escribir('puntos_interes.csv', [(i, f'Punto {i}', random.randint(1,6), random.randint(1,300)) for i in range(1, 1001)])
escribir('hotel_punto_interes.csv', [(h, p, round(random.uniform(0.1, 15), 2)) for h in range(1, HOTELES+1)
                                     for p in random.sample(range(1, 1001), 5)])

# Habitaciones: 4 tipos, 8 comodidades
escribir('tipos.csv', [(1,'Simple',1),(2,'Doble',2),(3,'Triple',3),(4,'Suite',4)])
coms = ['Wifi','Aire acondicionado','TV','Minibar','Caja fuerte','Jacuzzi','Balcon','Cocina']
escribir('comodidades.csv', [(i+1, c) for i, c in enumerate(coms)])
escribir('tipo_comodidad.csv', [(t, c) for t in range(1,5) for c in range(1, 2*t+1)])
hab = [((h-1)*HAB_POR_HOTEL + n, h, random.randint(1,4), str(100*(1 + (n-1)//10) + n), 1 + (n-1)//10)
       for h in range(1, HOTELES+1) for n in range(1, HAB_POR_HOTEL+1)]
escribir('habitaciones.csv', hab)

# Huéspedes con 1 teléfono y 1 email cada uno
apellidos = ['Gomez','Perez','Rodriguez','Fernandez','Lopez','Diaz','Martinez','Sanchez','Romero','Sosa']
nombres = ['Ana','Juan','Maria','Pedro','Lucia','Carlos','Sofia','Diego','Laura','Martin']
escribir('huespedes.csv', [(i, 'dni', 10_000_000 + i, random.randint(1,5), random.choice(nombres),
                            f'{random.choice(apellidos)}{i % 1000}', random.randint(1,300)) for i in range(1, HUESPEDES+1)])
escribir('telefonos.csv', [(i, 'movil', f'+54 9 351 {5000000+i}') for i in range(1, HUESPEDES+1)])
escribir('emails.csv',    [(i, f'huesped{i}@mail.com') for i in range(1, HUESPEDES+1)])

# Reservas: una detrás de otra por habitación (sin superposición)
total = 0
with open(os.path.join(OUT, 'reservas.csv'), 'w', newline='', encoding='utf-8') as f:
    w = csv.writer(f, lineterminator='\n')
    for hid in range(1, len(hab) + 1):
        d = INICIO + dt.timedelta(days=random.randint(0, 5))
        for _ in range(RES_POR_HAB):
            ini = d
            fin = ini + dt.timedelta(days=random.randint(1, 7))
            if fin <= HOY:
                estado = 'finalizada' if random.random() < 0.9 else 'cancelada'
            else:
                estado = random.choices(['pendiente','confirmada','cancelada'], [3,6,1])[0]
            con_tarifa = estado in ('confirmada','finalizada') or (estado == 'cancelada' and random.random() < 0.5)
            tarifa = f'{random.randint(30000, 250000)}.00' if con_tarifa else N
            crea = dt.datetime.combine(ini - dt.timedelta(days=random.randint(1, 90)), dt.time(random.randint(0,23)))
            conf = (crea + dt.timedelta(days=1)).strftime('%Y-%m-%d %H:00:00') if con_tarifa else N
            w.writerow((random.randint(1, HUESPEDES), hid, ini, fin, random.randint(1,4), estado, tarifa,
                        crea.strftime('%Y-%m-%d %H:00:00'), conf))
            total += 1
            d = fin + dt.timedelta(days=random.randint(0, 4))
print(f'reservas.csv listo: {total:,} filas')