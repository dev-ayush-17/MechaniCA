from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
import uvicorn

app = FastAPI(title="Mechanica API")

class LoginRequest(BaseModel):
    phone: str

class LoginResponse(BaseModel):
    message: str
    token: str

@app.post("/login", response_model=LoginResponse)
async def login(request: LoginRequest):
    # Mock authentication logic
    if not request.phone:
        raise HTTPException(status_code=400, detail="Phone number is required")
    
    # In a real app, verify phone, send OTP, verify OTP, generate JWT
    return LoginResponse(
        message="Login successful",
        token="mock_jwt_token_for_" + request.phone
    )

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
