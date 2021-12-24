/*
    Credit: Brian_Lee
    Gamemode: samp-open-roleplay (Brian-Less)

    เป็นระบบ AirDrop ใช้คำสั่งสร้างเพื่อเรียก AirDrop ลงมาจากฟ้า
    แล้วก็กดเก็บมีรางวัลใน AirDrop จะสุ่ม แล้ว 1-2 นาที AirDrop จะถูกทำล้าย
    หาก สร้าง AirDroP ออกมาแล้วไม่มีคนเก็บจะมีเวลา 10 นาที หากไม่มีการเก็บ AirDrop จะถูกทำลาย!
    
    หมายเหตุ:
    - หากเจอบัคสามารถติดต่อเราได้ที่
    - Github: https://github.com/BrianLee1973
*/

#include <YSI_Coding\y_hooks>
#include <YSI_Coding\y_timers>
#include <YSI_Server\y_colours>

#if 0

    //FACTION: สร้าง AirDrop หล่นลงมาจากฟ้าลงสู่พื้น
    forward CreateAirDropToFootBat(playerid);
    
    //FACTION: เก็บ AirDrop
    forward OnGabAirDrop(playerid, slot);

#endif

#define     MAX_AIRDROP     (10)


static
    bool: AirDrop_Exist[MAX_AIRDROP],
    AirDrop_Object[MAX_AIRDROP],
    AirDrop_Flash[MAX_AIRDROP], 
    AirDrop_Time[MAX_AIRDROP],
    Timer:AirDrop_UpdateText[MAX_AIRDROP],   
    STREAMER_TAG_3D_TEXT_LABEL:AirDrop_Text[MAX_AIRDROP],
    Iterator:AirDropIndex<MAX_AIRDROP>;

timer DestroyAirDropTimer[900*1000](slot)
{
    DestroyAirDrop(slot);
}

timer UpdateTextTimer[1000](slot)
{
    new
        hours,
        minutes,
        seconds,
        string[256]
    ;

    AirDrop_Time[slot]--;

    GetElapsedTime(AirDrop_Time[slot], hours, minutes, seconds);

    format(string, sizeof(string), ""YELLOW"[ AirDrop ]\n"WHITE"%02d:%02d:%02d\n"INDIANRED"(รางวัลอยู่ด้านใน 'AirDrop' รีบมาแย่งของดีกันเร็วๆ !)", hours, minutes, seconds);
    UpdateDynamic3DTextLabelText(AirDrop_Text[slot], -1, string);

    if(!AirDrop_Time[slot]) {
        stop AirDrop_UpdateText[slot];
        DestroyAirDrop(slot);
    }
}

timer SetTextAirDropTimer[10000](slot, Float:x, Float:y, Float:z)
{
    new
        string[256]
    ;

    format(string, sizeof(string), ""YELLOW"[ AirDrop ]\n"WHITE"00:00");
    AirDrop_Text[slot] = CreateDynamic3DTextLabel(string, -1, x, y, z, 5.0);

    AirDrop_UpdateText[slot] = repeat UpdateTextTimer[1000](slot);
}

hook OnPlayerKeyStateChange(playerid, newkeys, oldkeys)
{
    if(PRESSED(KEY_NO) && !IsPlayerInAnyVehicle(playerid))
    {
        new 
            Float:x, Float:y, Float:z
        ;

        foreach(new airdropindex: AirDropIndex)
        {
            GetDynamicObjectPos(AirDrop_Object[airdropindex], x, y, z); 
            if(IsPlayerInRangeOfPoint(playerid, 2.0, x, y, z))
            {
                if(AirDrop_Exist[airdropindex] == false) return SendClientMessage(playerid, -1, ""INDIANRED"Error: "WHITE"ถูกเก็บไปแล้ว 555+");
                if(!IsValidDynamicObject(AirDrop_Object[airdropindex])) return 1;

                ApplyAnimation(playerid, "BOMBER", "BOM_Plant", 4.0, 1, 0, 0, 0, 0, 1);
                CallLocalFunction("OnGabAirDrop", "ii", playerid, airdropindex);
                return Y_HOOKS_BREAK_RETURN_1;
            }
        }
    }   
    return 1;
}

CMD:createairdrop(playerid, params[]) {

    // จะทำให้สามารถสร้างได้แค่แอดมินก็มาดักเอาตรงนี้ 

    CallLocalFunction("CreateAirDropToFootBat", "i", playerid);
    return 1;
}

hook CreateAirDropToFootBat(playerid)
{
	new 
        Float:x, Float:y, Float:z,
        slot = Iter_Alloc(AirDropIndex)
    ;

    if(slot >= MAX_AIRDROP)
    {
        printf("Limit AirDrop : %d/%d -> Error Error Error", slot, MAX_AIRDROP);
        return -1;
    }

	if (slot == ITER_NONE)
	{
		return -1;
	}

    if(!AirDrop_Exist[slot]) {
        GetPlayerPos(playerid, x, y, z);

        AirDrop_Object[slot] = CreateDynamicObject(1685, x, y, z+90, 0, 0, 0);

        AirDrop_Flash[slot] = CreateDynamicObject(18728, x, y, z+85, 0, 0, 0); 

        MoveDynamicObject(AirDrop_Object[slot], x, y, z-0.4, 10.00);

        MoveDynamicObject(AirDrop_Flash[slot], x, y, z-1.4, 10.00);        

        AirDrop_Exist[slot] = true;
        AirDrop_Time[slot] = 30;

        defer DestroyAirDropTimer(slot);
        defer SetTextAirDropTimer(slot, x, y, z);
        Iter_Add(AirDropIndex, slot);
    }

    return 1;
}

hook OnGabAirDrop(playerid, slot)
{
    // คิด Logic การสุ่มไอเท็มใน Airdrop กันเอง ว่าจะให้มันออกยากหรือง่าย
    // ..

    switch(random(2)) // 50% | 50%
    {
        case 0: SendClientMessage(playerid, -1, "รวย");
        case 1: SendClientMessage(playerid, -1, "จน");
    }

    // Reset ค่า
    ClearAnimations(playerid);
    stop AirDrop_UpdateText[slot];
    DestroyAirDrop(slot);
    return 1;
}

stock DestroyAirDrop(slot)
{
    SendClientMessageToAllEx(-1, "{3399FF}[ {66CCFF}AirDrop OnAir {3399FF}] "WHITE"AirDrop ไอดีที่ (%i) ถูกทำลายแล้ว!", slot);
    DestroyDynamic3DTextLabel(AirDrop_Text[slot]);
    DestroyDynamicObject(AirDrop_Object[slot]);
    DestroyDynamicObject(AirDrop_Flash[slot]);
    AirDrop_Exist[slot] = false;
    Iter_Remove(AirDropIndex, slot);
    return 1;
}