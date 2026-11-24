import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles,Timer
async def xfer(dut,c,a=0,d=0):
    p=bytearray([0xA5,c])
    p+=a.to_bytes(4,"big")
    p+=d.to_bytes(4,"big")
    s=0
    for b in p:
        s^=b
    p.append(s)
    dut.ui_in.value=4
    await Timer(2,unit="us")
    dut.ui_in.value=0
    await Timer(1,unit="us")
    r=0
    for b in p:
        for i in range(7,-1,-1):
            m=(b>>i)&1
            dut.ui_in.value=m<<1
            await Timer(1,unit="us")
            r=(r<<1)|(int(dut.uo_out.value)&1)
            dut.ui_in.value=(m<<1)|1
            await Timer(1,unit="us")
            dut.ui_in.value=m<<1
            await Timer(1,unit="us")
    dut.ui_in.value=4
    await ClockCycles(dut.clk,8)
    return r
@cocotb.test()
async def test_project(dut):
    clock=Clock(dut.clk,100,unit="ns")
    cocotb.start_soon(clock.start())
    dut.ena.value=1
    dut.ui_in.value=4
    dut.uio_in.value=0
    dut.rst_n.value=0
    await ClockCycles(dut.clk,10)
    dut.rst_n.value=1
    await ClockCycles(dut.clk,10)
    prog=[0x0A,0x01,0x03,0x02,0x12,0x13,0xFE,0xDF]
    for i,b in enumerate(prog):
        await xfer(dut,0x01,i,b)
    await xfer(dut,0x10)
    await ClockCycles(dut.clk,200)
    await xfer(dut,0x11)
    await ClockCycles(dut.clk,20)
    await xfer(dut,0x20,3)
    r=await xfer(dut,0x00)
    assert((r>>80)&0xFF)==0x5A
    assert((r>>72)&0xFF)==0
    assert((r>>40)&0xFFFFFFFF)==13
