import { BrowserRouter as Router, Routes, Route } from 'react-router-dom';
import SpacesList from './pages/SpacesList';
import InboxDetail from './pages/InboxDetail';
import SpaceDetail from './pages/SpaceDetail';
import Auth from './components/Auth';

function App() {
  return (
    <Auth>
      {(session) => (
        <Router>
          <div className="min-h-screen text-white">
            <Routes>
              <Route path="/" element={<SpacesList session={session} />} />
              <Route path="/inbox" element={<InboxDetail session={session} />} />
              <Route path="/space/:id" element={<SpaceDetail session={session} />} />
            </Routes>
          </div>
        </Router>
      )}
    </Auth>
  );
}

export default App;
