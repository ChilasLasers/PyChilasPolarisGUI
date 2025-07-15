#****************************************************************************
#This file is part of Chilas Polaris.
#
#Chilas Polaris is free software: you can redistribute it and/or modify
#it under the terms of the GNU General Public License as published by
#the Free Software Foundation, either version 3 of the License, or
#(at your option) any later version.
#
#Chilas Polaris is distributed in the hope that it will be useful,
#but WITHOUT ANY WARRANTY; without even the implied warranty of
#MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
#GNU General Public License for more details.
#
#You should have received a copy of the GNU General Public License
#along with this program. If not, see <https://www.gnu.org/licenses/>.
#****************************************************************************

from PySide2.QtCore import QObject, Slot, QUrl

from serial.tools.list_ports import comports
import serial
import struct
import time
from concurrent.futures import ThreadPoolExecutor


class pyLaser(QObject):
    def __init__(self):
        QObject.__init__(self)
        self.ser = None
        self.executor = ThreadPoolExecutor(max_workers=1)
        self.gui_func = { name: getattr(self, name) for name in dir(self) if name.startswith("_") }

    @Slot(result=list)
    def listPorts(self):
        self.ports = []
        self.portList = []
        for n, (port, desc, hwid) in enumerate(sorted(comports()), 1):
            self.ports.append(port)
            self.portList.append(port + " - " + desc)
        #print(comports()[0].hwid, "---", comports()[0].vid, "---", comports()[0].pid, "---", comports()[0].serial_number, "---", comports()[0].manufacturer,  "---", comports()[0].product)
        return self.portList

    @Slot(int, int, result=str)
    def ioPort(self, io, port):
        if io:
            if(self.ser is None):
                try:
                    self.ser = serial.Serial(self.ports[port],
                                             9600,
                                             serial.EIGHTBITS,
                                             serial.PARITY_NONE,
                                             serial.STOPBITS_ONE,
                                             3)
                    return "0"
                except serial.SerialException as e:
                    return (str(e))
            else:
                return "1"
        else:
            if(self.ser is not None):
                try:
                    self.ser.close()
                    self.ser = None
                    return "0"
                except:
                    return "1"
            return "1"

    def crcCheck(self, data):
        crc = 0xFFFF
        for byte in data:
            crc ^= byte
            for _ in range(8):
                if (crc & 0x0001):
                    crc >>= 1
                    crc ^= 0xA001
                else:
                    crc >>= 1
        return crc

    def write(self, slave, func, reg, dl, d=None, cf=0):
        command = (slave.to_bytes(1, 'big')+
                    func.to_bytes(1, 'big')+
                    reg.to_bytes(2, 'big')+
                    dl.to_bytes(2, 'big'))
        if d is not None:
            if (cf == 0):
                command += d.to_bytes(dl, 'big')
            elif (cf == 1):
                command += struct.pack('>f', d)
        command += self.crcCheck(command).to_bytes(2, 'little')
        #print("Trying to send %s" % command.hex())
        if(self.ser is not None):
            self.ser.write(command)
            #print("%s sent." % command.hex())
        else:
            return "0"

    def read(self, dl=0):
        if(self.ser is not None):
            resp = self.ser.read(1+1+2+2+dl+2)
            #print("%s received." % resp.hex())
            parsedResp = self.parseResp(resp)
            if not int.from_bytes(parsedResp["crc_received"], 'little') == self.crcCheck(resp[:-2]):
                print("CRC Fail! Expected CRC: %#x, got %#x" % (self.crcCheck(resp[:-2]), int.from_bytes(parsedResp["crc_received"], 'little')))
            return parsedResp
        else:
            return "0"

    def parseResp(self, response):
        slave_station_number = response[0]
        function_code = response[1]
        if (function_code == 0x03) or (function_code == 0x10):
            register_address = response[2:4]
            data_length = response[4:6]
            data = response[6:-2]
            crc_received = response[-2:]
            return {
                "slave_station_number": slave_station_number,
                "function_code": function_code,
                "register_address": register_address,
                "data_length": data_length,
                "data": data,
                "crc_received": crc_received
            }
        elif (function_code == 0x01) or (function_code == 0x05):
            data_length = response[2:4]
            data = response[4:-2]
            crc_received = response[-2:]
            return {
                "slave_station_number": slave_station_number,
                "function_code": function_code,
                "data_length": data_length,
                "data": data,
                "crc_received": crc_received
            }

    def _getSN(self):
        self.write(0x01, 0x03, 0x0018, 0x0008)
        return ("SN"+self.read(8)["data"].decode('ascii'))

    def _getVer(self):
        self.write(0x01, 0x03, 0x0028, 0x0006)
        return self.read(6)["data"].decode('ascii')

    def _getPcbTemp(self):
        self.write(0x01, 0x03, 0x007a, 0x0004)
        return "{:.2f}".format(struct.unpack('>f', self.read(4)["data"])[0])

    def _getTecTemp(self):
        self.write(0x01, 0x03, 0x007e, 0x0004)
        return "{:.2f}".format(struct.unpack('>f', self.read(4)["data"])[0])

    def _getTecTempSet(self):
        self.write(0x01, 0x03, 0x0072, 0x0004)
        return "{:.2f}".format(struct.unpack('>f', self.read(4)["data"])[0])

    def _getLdCur(self):
        self.write(0x01, 0x03, 0x0082, 0x0004)
        return "{:.2f}".format(struct.unpack('>f', self.read(4)["data"])[0])

    def _getLdCurSet(self):
        self.write(0x01, 0x03, 0x0076, 0x0004)
        return "{:.2f}".format(struct.unpack('>f', self.read(4)["data"])[0])

    def _getTecCur(self):
        self.write(0x01, 0x03, 0x008a, 0x0004)
        return "{:.2f}".format(struct.unpack('>f', self.read(4)["data"])[0])

    def _mode(self, arg=None):
        if arg is None:
            self.write(0x01, 0x03, 0x008e, 0x0001)
        else:
            if arg[0]:
                self.write(0x01, 0x10, reg=0x008e, dl=0x0001, d=0x01)
            else:
                self.write(0x01, 0x10, 0x008e, 0x0001, 0x00)
        return str(int.from_bytes(self.read(1)["data"], 'big') & 1)

    def _setLd(self, arg):
        if arg[0]:
            self.write(0x01, 0x05, 0x0002, 0x0001)
        else:
            self.write(0x01, 0x05, 0x0002, 0x0000)
        return str(int.from_bytes(self.read(0)["data"], 'big') & 1)

    def _setTecTemp(self, arg):
        self.write(slave=0x01, func=0x10, reg=0x0072, dl=0x0004, d=arg[0], cf=1)
        return "{:.2f}".format(struct.unpack('>f', self.read(4)["data"])[0])

    def _setLdCur(self, arg):
        self.write(0x01, 0x10, 0x0076, 0x0004, arg[0], cf=1)
        return "{:.2f}".format(struct.unpack('>f', self.read(4)["data"])[0])

    def _getDevStat(self):
        self.write(0x01, 0x01, 0x0000, 0x0003)
        return str(int.from_bytes(self.read(0)["data"], 'big'))

    @Slot(str, result=str)
    @Slot(str, list, result=str)
    def _executor(self, func: str, args: list=None):
        if(self.ser is not None):
            try:
                if args is None:
                    future = self.executor.submit(self.gui_func[func])
                else:
                    future = self.executor.submit(self.gui_func[func], args)
                return future.result()
            except serial.SerialException as e:
                print(str(e))
                return "0"
        else:
            return "0"
